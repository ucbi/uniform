defmodule Uniform.Modifiers do
  @moduledoc """
  Utilities for building code transformations with `modify` in your
  `Uniform.Blueprint` module.
  """

  #
  # Code Fences
  #

  @doc """
  Build code transformations to apply [Code
  Fences](code-transformations.html#code-fences) with this function.

  Note that code fences are already applied automatically to `.ex/.exs` files
  as well as `.js/.jsx/.ts/.tsx` files.

  This function is automatically imported in your Blueprint.

  ## Examples

      # code fences for SQL files
      modify ~r/\.sql$/, &code_fences(&1, &2, "--")

      # code fences for Rust files
      modify ~r/\.rs$/, fn file, app ->
        code_fences(file, app, "//")
      end

  """
  @spec code_fences(String.t(), Uniform.App.t(), String.t()) :: String.t()
  def code_fences(file_contents, app, comment_prefix) do
    remove_regex =
      Regex.compile!(
        "\n *#{comment_prefix} uniform:remove.+?#{comment_prefix} \/uniform:remove",
        "s"
      )

    # A regex that detects code fences
    "\n *#{comment_prefix} uniform:(lib|mix|app):([a-z0-9_]+)(.+?)#{comment_prefix} \/uniform:\\1:\\2"
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
      raise "Code fence '# uniform:lib:#{dep_name} references a lib dependency that isn't a directory in lib/"
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
      raise "Code fence '# uniform:mix:#{dep_name} references a mix dependency that isn't in `deps` in mix.exs"
    end
  end

  defp code_fence_replacement(app, "app", app_name, inner_match) do
    if to_string(app_name) == app.name.underscore do
      inner_match
    else
      ""
    end
  end

  @doc """
       Code fences are in this format:

           some_code()

           # uniform:lib:foo_bar
           #
           # ... code that will be removed if the lib called foo_bar isn't included
           #
           # /uniform:lib:foo_bar

           more_code()

           # uniform:mix:foo_bar
           #
           # ... code that will be removed if the mix dep called foo_bar isn't included
           #
           # /uniform:mix:foo_bar

           more_code()

           # uniform:app:foo_bar
           #
           # ... code that will be removed if the current app isn't called foo_bar
           #
           # /uniform:app:foo_bar

           more_code()

           # uniform:remove
           #
           # ... code that will always be removed upon ejection
           #
           # /uniform:remove

       """ && false
  def elixir_code_fences(file_contents, app) do
    code_fences(file_contents, app, "#")
  end

  @doc false
  def js_code_fences(file_contents, app) do
    code_fences(file_contents, app, "//")
  end

  #
  # mix.exs Dependency Removal
  #

  @doc """
       Given the contents of a mix.exs file and an `%App{}`, look for the `defp
       deps` function and filter out the deps that should not be included in
       this app.
       """ && false
  def remove_unused_mix_deps(file_contents, app) do
    zipper =
      file_contents
      |> Sourceror.parse_string()
      |> Sourceror.Zipper.zip()
      |> Sourceror.Zipper.find(:next, fn
        {:defp, _, [{:deps, _, nil}, _]} ->
          true

        _ ->
          false
      end)

    defp_deps = if zipper, do: Sourceror.Zipper.node(zipper)

    unless defp_deps do
      raise """
      mix.exs is not set up properly.

      Uniform expects your mix.exs file to have the default structure generated
      by standard tools like `mix new` and `mix phx.new`.

      It should have a private `deps` function which returns a list of deps.

          defp deps do
            [
              {:gettext, "~> 0.20"},
              {:phoenix, "~> 1.6"},
              ...
            ]
          end

      The `project` function should use deps() like this.

          def project do
            [
              deps: deps(),
              ...
            ]
          end

      """
    end

    start_line = Sourceror.get_line(defp_deps)
    end_line = Sourceror.get_end_line(defp_deps)
    lines = String.split(file_contents, "\n")
    prelude = Enum.slice(lines, 0..(start_line - 2))
    postlude = Enum.slice(lines, end_line..-1)
    all_deps = app.internal.config.mix_project.project()[:deps]

    new_deps =
      for dep <- all_deps, dep_name(dep) in app.internal.deps.included.mix do
        {name, version, opts} =
          case dep do
            {name, ver} when is_binary(ver) ->
              {name, ver, nil}

            {name, opts} ->
              validate_opts!(name, opts) && {name, nil, opts}

            {name, ver, opts} when is_binary(ver) ->
              validate_opts!(name, opts) && {name, ver, opts}
          end

        tuple_contents =
          [
            name && inspect(name),
            version && inspect(version),
            opts && String.slice(inspect(opts), 1..-2)
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.intersperse(", ")

        ["      {", tuple_contents, "},\n"]
      end

    new_defp_deps = [
      "\n",
      "  defp deps do\n",
      "    [\n",
      new_deps,
      "    ]\n",
      "  end\n"
    ]

    IO.iodata_to_binary([
      Enum.intersperse(prelude, "\n"),
      new_defp_deps,
      Enum.intersperse(postlude, "\n")
    ])
  end

  defp validate_opts!(dep, opts) do
    unless Keyword.keyword?(opts) do
      raise """
      Options given in mix.exs deps are not a keyword list.

      Dependency: #{inspect(dep)}
      Received: #{inspect(opts)}

      See valid formats in the docs:

          https://hexdocs.pm/mix/1.13/Mix.Tasks.Deps.html

      """
    end

    :ok
  end

  defp dep_name({dep, _version_or_opts}), do: dep
  defp dep_name({dep, _version, _opts}), do: dep

  #
  # Base Project Name Replacement
  #

  @doc "Replace the base project name with the ejected app name." && false
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
