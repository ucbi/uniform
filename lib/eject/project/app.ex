defmodule Eject.Project.App do
  defmacro __using__(_) do
    quote do
      import Eject.Project.App, only: [eject: 2]
    end
  end

  @doc """
  Specify various rules to apply to the ejected app `lib/` directory files. These are the
  same "file rules" that can be applied to a lib dep. See `Eject.Rules` for a full
  list of options.
  """
  defmacro eject(app, do: block) do
    {:__block__, [], items} = block

    items =
      Enum.map(items, fn
        {:if, meta, [condition, [do: {:__block__, [], items}]]} ->
          {:if, meta, [condition, [do: items]]}

        item ->
          item
      end)

    quote do
      try do
        import Eject.Project.App, except: [eject: 1]
        def __app__(unquote(app)), do: unquote(items) |> List.flatten() |> Enum.reject(&is_nil/1)
      after
        :ok
      end
    end
  end

  def lib_dep(name), do: {:lib_dep, name}
  def mix_dep(name), do: {:mix_dep, name}
  def file(path), do: {:text, path}
  def template(path), do: {:template, path}
  def cp_r(path), do: {:cp_r, path}
  def cp(path), do: {:cp, path}
  def preserve(path), do: {:preserve, path}
end
