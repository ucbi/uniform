defmodule Eject.Plan.BeforeCompile do
  defmacro __before_compile__(_env) do
    quote do
      def __modifiers__, do: @modifiers
    end
  end
end

defmodule Eject.Plan do
  @doc """
  Returns a keyword list of additional key value pairs available to _all_ ejectable apps.

  As an example, you may want to set the theme based on the name of the ejectable app.
  In this case, add an 'extra' entry called 'theme', which will then be available through the
  app struct:

      def extra(app) do
        theme =
          case app.name.underscore do
            "work_" <> _ -> :work
            "personal_" <> _ -> :personal
            _ -> raise "App name must start with Work or Personal to derive theme."
          end

        [theme: theme]
      end

  For app specific pairs, use the `extra` option in the app's manifest. See `Eject.Manifest`.
  """
  @callback extra(Eject.App.t()) :: keyword

  @doc """
  Use this callback to modify the path of ejected files. It will be called for
  every file in a lib directory, along with every file specified via `file`, `template`,
  `cp`, and `cp_r`.

  If you don't want to modify the `path`, just return it.

  If not defined, the default implementation is:

      def target_path(path, _app), do: path

  """
  @callback target_path(Path.t(), Eject.App.t()) :: Path.t()

  @doc """
  A macro for defining an ejection plan.

  The required `templates` path points to the EEx templates used by `Eject`.

  ### Examples

      defmodule MyBaseApp.Eject.Project do
        use Eject.Plan, templates: "lib/my_base_app/eject/templates"
      ...

  """
  defmacro __using__(opts) do
    templates = opts[:templates]

    quote do
      @behaviour Eject.Plan
      @before_compile Eject.Plan.BeforeCompile
      import Eject.Plan, only: [modify: 4, modify: 3, deps: 1, eject: 2]
      import Eject.App, only: [depends_on?: 3]

      def __template_dir__, do: unquote(templates)

      def target_path(path, _app), do: path
      defoverridable target_path: 2

      Module.register_attribute(__MODULE__, :lib_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :mix_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :modifiers, accumulate: true)
    end
  end

  #
  # Modifying the contents of a file
  #

  @doc """
  Specify a file or regex pattern and a transformation function to apply to all files matching that pattern.

  ### Example

      modify ~r/lib\/.+_(worker|cron).ex/, file, app do
        # Return modified `file` string
        # Only ran on files matching the regex
      end

      modify "lib/my_app_web/router.ex", file, app do
        # Return modified `file` string
        # Only ran on files with the exact path "lib/my_app_web/router.ex"
      end

  """
  defmacro modify(path_or_regex, file, app \\ nil, do: block) do
    line = __CALLER__.line
    fn_name = String.to_atom("modify_#{line}")

    quote do
      Eject.Plan.__register_modifier__(__MODULE__, unquote(path_or_regex), unquote(fn_name))
      def unquote(fn_name)(unquote(file), unquote(app)), do: unquote(block)
    end
  end

  def __register_modifier__(mod, path_or_regex, fn_name) do
    Module.put_attribute(mod, :modifiers, {path_or_regex, {mod, fn_name}})
  end

  #
  # Configuring which files to eject outside of the files in the app's `lib` directory.
  #

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
        import Eject.Plan, except: [eject: 1, only: 1]

        def __eject__(unquote(app)),
          do: unquote(items) |> List.flatten() |> Enum.reject(&is_nil/1)
      after
        :ok
      end
    end
  end

  #
  # Dependencies
  #

  defmacro deps(do: block) do
    prelude =
      quote do
        try do
          import Eject.Plan, only: [lib: 1, lib: 2, mix: 1, mix: 2, always: 1]
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

        def __deps__(:lib), do: unquote(Macro.escape(lib_deps))
        def __deps__(:mix), do: unquote(Macro.escape(mix_deps))
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
      try do
        import Eject.Plan
        Eject.Plan.__lib__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  defmacro lib(name) do
    quote do
      Eject.Plan.__lib__(__MODULE__, unquote(name), [], @deps_always_block)
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
  defmacro mix(name, do: block) do
    opts =
      case block do
        {:__block__, _meta, opts} -> opts
        opt -> [opt]
      end

    quote do
      try do
        import Eject.Plan, only: [mix_deps: 1]
        Eject.Plan.__mix__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  defmacro mix(name) do
    quote do
      Eject.Plan.__mix__(__MODULE__, unquote(name), [], @deps_always_block)
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

  # Specifying files/directories to copy
  def file(path, opts \\ []), do: {:text, {path, opts}}
  def template(path, opts \\ []), do: {:template, {path, opts}}
  def cp_r(path, opts \\ []), do: {:cp_r, {path, opts}}
  def cp(path, opts \\ []), do: {:cp, {path, opts}}

  # Specifying files/directories to NOT delete when clearing the destination prior the ejection
  def preserve(path), do: {:preserve, path}

  # Specifying allow/deny-lists that drive which files to include in a lib directory
  def except(paths), do: {:except, List.wrap(paths)}
  def only(paths), do: {:only, List.wrap(paths)}
end
