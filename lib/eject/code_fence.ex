defmodule Eject.CodeFence do
  # A regex that detects code fences
  @code_fence_regex ~r/\n *# <eject:(lib|mix|app):([a-z0-9_]+)>(.+?)# <\/eject:\1:\2>/s

  @doc """
  Code fences are in this format:

      some_code()

      # <eject:lib:foo_bar>
      #
      # ... code that will be removed if the lib called foo_bar isn't included
      #
      # </eject:lib:foo_bar>

      more_code()

      # <eject:mix:foo_bar>
      #
      # ... code that will be removed if the mix dep called foo_bar isn't included
      #
      # </eject:mix:foo_bar>

      more_code()

      # <eject:app:foo_bar>
      #
      # ... code that will be removed if the current app isn't called foo_bar
      #
      # </eject:app:foo_bar>

      more_code()

      # <eject:remove>
      #
      # ... code that will always be removed upon ejection
      #
      # </eject:remove>

  """
  def apply_fences(file_contents, app) do
    @code_fence_regex
    |> Regex.replace(
      file_contents,
      fn _, category, dep, code ->
        dep = String.to_existing_atom(dep)
        code_fence_replacement(app, category, dep, code)
      end,
      global: true
    )
    |> String.replace(~r/\n *# <eject:remove>.+?<\/eject:remove>/s, "")
  rescue
    e in ArgumentError ->
      if String.contains?(e.message, "not an already existing atom") do
        {:erlang, :binary_to_existing_atom, [dependency_name, :utf8], _} =
          List.first(__STACKTRACE__)

        reraise "Code fence references a lib dependency `#{dependency_name}` that isn't defined in lib_deps/mix_deps",
                __STACKTRACE__
      else
        reraise e, __STACKTRACE__
      end
  end

  defp code_fence_replacement(app, "lib", dep_name, inner_match) do
    if dep_name in app.deps.all.lib do
      if dep_name in app.deps.included.lib do
        String.trim_trailing(inner_match)
      else
        ""
      end
    else
      raise "Code fence '# <eject:lib:#{dep_name}> references a lib dependency that isn't defined in `def lib_deps`"
    end
  end

  defp code_fence_replacement(app, "mix", dep_name, inner_match) do
    if dep_name in app.deps.all.mix do
      if dep_name in app.deps.included.mix do
        String.trim_trailing(inner_match)
      else
        ""
      end
    else
      raise "Code fence '# <eject:mix:#{dep_name}> references a mix dependency that isn't defined in `def mix_deps`"
    end
  end

  defp code_fence_replacement(app, "app", app_name, inner_match) do
    if to_string(app_name) == app.name.snake do
      inner_match
    else
      ""
    end
  end
end
