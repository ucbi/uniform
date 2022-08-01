defmodule Eject.Modifiers do
  @moduledoc false

  #
  # mix.exs Dependency Removal
  #

  @doc """
  Given the contents of a mix.exs file and an `%App{}`,
  look for the following code fence that should be wrapping the mix deps:

      # eject:deps

      ...

      # /eject:deps

  ...and filter out the deps that should not be included in this app.
  """
  def remove_unused_mix_deps(file_contents, app) do
    file_contents
    |> String.replace(~r/\n *# eject:deps(.+?)# \/eject:deps/s, fn deps ->
      deps
      |> Code.string_to_quoted!()
      |> Enum.filter(&(dep_name(&1) in app.internal.deps.included.mix))
      |> Macro.to_string()
    end)
  end

  defp dep_name({dep, version}) when is_binary(version), do: dep
  defp dep_name({dep, opts}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, _version, opts]}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, opts]}) when is_list(opts), do: dep
  defp dep_name(quoted), do: raise("did not parse quoted AST `#{inspect(quoted)}` in mix deps")

  #
  # Code Fences
  #

  def elixir_code_fences(file_contents, app) do
    code_fences(file_contents, app, "#")
  end

  def js_code_fences(file_contents, app) do
    code_fences(file_contents, app, "//")
  end

  @doc """
  Code fences are in this format:

      some_code()

      # eject:lib:foo_bar
      #
      # ... code that will be removed if the lib called foo_bar isn't included
      #
      # /eject:lib:foo_bar

      more_code()

      # eject:mix:foo_bar
      #
      # ... code that will be removed if the mix dep called foo_bar isn't included
      #
      # /eject:mix:foo_bar

      more_code()

      # eject:app:foo_bar
      #
      # ... code that will be removed if the current app isn't called foo_bar
      #
      # /eject:app:foo_bar

      more_code()

      # eject:remove
      #
      # ... code that will always be removed upon ejection
      #
      # /eject:remove

  """
  def code_fences(file_contents, app, comment_prefix) do
    remove_regex =
      Regex.compile!(
        "\n *#{comment_prefix} eject:remove.+?#{comment_prefix} \/eject:remove",
        "s"
      )

    # A regex that detects code fences
    "\n *#{comment_prefix} eject:(lib|mix|app):([a-z0-9_]+)(.+?)#{comment_prefix} \/eject:\\1:\\2"
    |> Regex.compile!("s")
    |> Regex.replace(
      file_contents,
      fn _, category, dep, code ->
        dep = String.to_existing_atom(dep)
        code_fence_replacement(app, category, dep, code)
      end,
      global: true
    )
    |> String.replace(remove_regex, "")
  rescue
    e in ArgumentError ->
      if String.contains?(e.message, "not an already existing atom") do
        {:erlang, :binary_to_existing_atom, [dependency_name, :utf8], _} =
          List.first(__STACKTRACE__)

        reraise "Code fence references a lib dependency `#{dependency_name}` that isn't a directory in lib/",
                __STACKTRACE__
      else
        reraise e, __STACKTRACE__
      end
  end

  defp code_fence_replacement(app, "lib", dep_name, inner_match) do
    if dep_name in app.internal.deps.all.lib do
      if dep_name in app.internal.deps.included.lib do
        String.trim_trailing(inner_match)
      else
        ""
      end
    else
      raise "Code fence '# eject:lib:#{dep_name} references a lib dependency that isn't a directory in lib/"
    end
  end

  defp code_fence_replacement(app, "mix", dep_name, inner_match) do
    if dep_name in app.internal.deps.all.mix do
      if dep_name in app.internal.deps.included.mix do
        String.trim_trailing(inner_match)
      else
        ""
      end
    else
      raise "Code fence '# eject:mix:#{dep_name} references a mix dependency that isn't in `deps` in mix.exs"
    end
  end

  defp code_fence_replacement(app, "app", app_name, inner_match) do
    if to_string(app_name) == app.name.underscore do
      inner_match
    else
      ""
    end
  end

  #
  # Base Project Name Replacement
  #

  @doc "Replace the base project name with the ejected app name."
  def replace_base_project_name(file_contents, app) do
    underscore = to_string(app.internal.config.mix_project_app)

    file_contents
    # replace `base_project_name` with `ejected_app_name`
    |> String.replace(underscore, app.name.underscore)
    # replace `base-project-name` with `ejected-app-name`
    |> String.replace(String.replace(underscore, "_", "-"), app.name.hyphen)
    # replace `BaseProjectName` with `EjectedAppName`
    |> String.replace(Macro.camelize(underscore), app.name.camel)
  end
end
