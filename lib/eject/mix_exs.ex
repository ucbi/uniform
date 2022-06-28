defmodule Eject.MixExs do
  @doc """
  Given the contents of a mix.exs file and an `%App{}`,
  look for the following code fence that should be wrapping the mix deps:

      # <eject:deps>

      ...

      # </eject:deps>

  ...and filter out the deps that should not be included in this app.
  """
  def remove_unused_deps(file_contents, app) do
    file_contents
    |> String.replace(~r/\n *# <eject:deps>(.+?)# <\/eject:deps>/s, fn deps ->
      deps
      |> Code.string_to_quoted!()
      |> Enum.filter(&include_dep?(&1, app))
      |> Macro.to_string()
    end)
  end

  # Return whether to include a dep.
  @spec include_dep?(quoted :: Macro.t(), Eject.App.t()) :: boolean
  defp include_dep?(quoted, app) do
    dep_name = dep_name(quoted)

    if dep_name in app.deps.all.mix do
      # This is an excludable mix dep, so only include it if this app
      # specifies to include it. This can happen via eject.exs,
      # or by another mix dep or lib dep requiring it.
      Map.has_key?(app.deps.mix, dep_name)
    else
      true
    end
  end

  defp dep_name({dep, version}) when is_binary(version), do: dep
  defp dep_name({dep, opts}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, _version, opts]}) when is_list(opts), do: dep
  defp dep_name({:{}, _meta, [dep, opts]}) when is_list(opts), do: dep
  defp dep_name(quoted), do: raise("did not parse quoted AST `#{inspect(quoted)}` in mix deps")
end
