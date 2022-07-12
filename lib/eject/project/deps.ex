defmodule Eject.Project.Deps do
  defmacro __using__(_) do
    quote do
      import Eject.Project.Deps, only: [deps: 1]
      Module.register_attribute(__MODULE__, :lib_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :mix_deps, accumulate: true)
    end
  end

  defmacro deps(do: block) do
    prelude =
      quote do
        try do
          import Eject.Project.Deps
          @deps_always_block false
          unquote(block)
        after
          :ok
        end
      end

    postlude =
      quote unquote: false do
        lib_deps = @lib_deps |> Enum.reverse()
        mix_deps = @mix_deps |> Enum.reverse()

        def __lib_deps__, do: unquote(Macro.escape(lib_deps))
        def __mix_deps__, do: unquote(Macro.escape(mix_deps))
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  defmacro always(do: block) do
    quote do
      try do
        @deps_always_block true
        unquote(block)
      after
        @deps_always_block false
      end
    end
  end

  @doc """
  Lib dependencies are identified by an atom that corresponds to the lib directory. For
  example, `:my_cool_utilities` ejects _all_ files in the `lib/my_cool_utilities` directory.
  If additional files from a different directory are needed, use the `associated_files` option.
  If you only need selected files from the `lib` directory, use the `only` option.

  Each ejectable app may elect to include the lib dependency by adding it
  to its `Eject` manifest (see `Eject.Manifest`).

  Options include:

    - `always: true` - _always_ include the lib dependency. In this case, there is no need
      to also list the dependency in its `Eject` manifest.
    - `lib_deps: atom | [atom]`  - other lib dependencies that the lib requires (i.e. nested dependencies).
      Note that each nested dependency itself must also have an entry on the "top" level of the list.
    - `mix_deps` - mix dependencies that the lib requires.
    - `associated_files` - files in another directory to also include with the lib directory (e.g. mocks).
    - `only` - only include _specific_ files from the lib directory, as opposed to _all_ files (the default behavior).
    - `except` - exclude specific files from the lib directory.

  """
  defmacro lib(name, do: block) do
    opts =
      case block do
        {:__block__, _meta, opts} -> opts
        opt -> [opt]
      end

    quote do
      Eject.Project.Deps.__lib__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
    end
  end

  defmacro lib(name) do
    quote do
      Eject.Project.Deps.__lib__(__MODULE__, unquote(name), [], @deps_always_block)
    end
  end

  @doc false
  def __lib__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
    lib_dep =
      Eject.LibDep.new!(%{
        name: name,
        lib_deps: opts |> Keyword.get(:lib_deps, []) |> List.wrap(),
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap(),
        always: always,
        file_rules: opts |> rule_opts() |> Eject.Rules.new()
      })

    Module.put_attribute(mod, :lib_deps, lib_dep)
  end

  @doc """
  Options include:
    - `mix_deps: atom | [atom]` - other mix dependencies that the mix requires (i.e. nested dependencies).
      Note that each nested dependency itself must also have an entry on the "top" level of the list.
  """
  defmacro mix(name, opts \\ []) do
    quote do
      Eject.Project.Deps.__mix__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
    end
  end

  @doc false
  def __mix__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
    mix_dep =
      Eject.MixDep.new!(%{
        name: name,
        always: always,
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap()
      })

    Module.put_attribute(mod, :mix_deps, mix_dep)
  end

  defmacro mix_deps(deps), do: {:mix_deps, List.wrap(deps)}
  defmacro lib_deps(deps), do: {:lib_deps, List.wrap(deps)}
  defmacro file(path), do: {:text, path}
  defmacro template(path), do: {:template, path}
  defmacro cp(path), do: {:cp, path}
  defmacro cp_r(path), do: {:cp_r, path}
  defmacro except(paths_or_regexs), do: {:except, List.wrap(paths_or_regexs)}
  defmacro lib_directory(function), do: {:lib_directory, function}
  defmacro only(paths_or_regexs), do: {:only, List.wrap(paths_or_regexs)}

  defp rule_opts(opts) do
    associated_files =
      Enum.flat_map(opts, fn opt ->
        case opt do
          {type, path_or_paths} when type in [:text, :template, :cp, :cp_r] ->
            path_or_paths
            |> List.wrap()
            |> Enum.map(&{type, &1})

          _ ->
            []
        end
      end)

    Keyword.put(opts, :associated_files, associated_files)
  end
end
