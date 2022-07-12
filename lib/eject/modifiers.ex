defmodule Eject.Modifiers do
  @doc """
  Given the contents of a mix.exs file and an `%App{}`,
  look for the following code fence that should be wrapping the mix deps:

      # <eject:deps>

      ...

      # </eject:deps>

  ...and filter out the deps that should not be included in this app.
  """
  def remove_unused_mix_deps(file_contents, app) do
    file_contents
    |> String.replace(~r/\n *# <eject:deps>(.+?)# <\/eject:deps>/s, fn deps ->
      deps
      |> Code.string_to_quoted!()
      |> Enum.filter(&(dep_name(&1) in app.deps.included.mix))
      |> Macro.to_string()
    end)
  end

  defp dep_name({dep, version}) when is_binary(version), do: dep
  defp dep_name({dep, opts}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, _version, opts]}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, opts]}) when is_list(opts), do: dep
  defp dep_name(quoted), do: raise("did not parse quoted AST `#{inspect(quoted)}` in mix deps")
end
