defmodule Eject do
  @moduledoc """
  A tool for "ejecting" applications from a "base" Elixir project into separate,
  standalone code repositories and releases.

  By belonging to a base application, each ejectable app is configured and managed
  in a consistent, coordinated, and maintainable fashion.

  ### Benefits

  `Eject` allows you to:
    - spin up new ejectable apps quickly and easily
    - upgrade dependencies once in the base app to upgrade all ejectable apps
    - easily share custom library code (e.g. utilities, UI)
    - run / test all ejectable apps locally at the same time

  ### Configuration

  `Eject` offers the following configuration options:
    - `project` - Required. Sets the base 'project module' that implements `Eject`.
    - `templates` - Required. Sets the file path for `Eject` templates.
    - `destination` - Optional. Sets the file path for the ejected apps. If omitted,
        defaults to one level up from the `project` folder (i.e. `../`).

    For example:

      config :my_base_app, Eject, project: MyBaseApp.Eject.Project

  ### Usage

      $ mix eject Tweeter

  See `Mix.Tasks.App.Eject` for details.

  """

  require Logger

  @doc """
  A macro for using the eject in a project.

  The required `templates` path points to the EEx templates used by `Eject`.

  ### Examples

      defmodule MyBaseApp.Eject.Project do
        use Eject, templates: "lib/my_base_app/eject/templates"
      ...

  """
  defmacro __using__(opts) do
    templates = opts[:templates]

    quote do
      @behaviour Eject
      require Eject

      import Eject,
        only: [
          app: 1,
          dir: 1,
          file: 1,
          lib: 2,
          mix: 2,
          modify: 4,
          preserve: 1,
          project: 1,
          template: 1
        ]

      import Eject.App, only: [depends_on?: 3]
      def __template_dir, do: unquote(templates)

      Module.register_attribute(__MODULE__, :app_options, [])
      Module.register_attribute(__MODULE__, :lib_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :mix_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :modifiers, accumulate: true)
      Module.register_attribute(__MODULE__, :files, accumulate: true)
      Module.register_attribute(__MODULE__, :directories, accumulate: true)
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      Module.register_attribute(__MODULE__, :preserve, accumulate: true)
    end
  end

  defmacro project(do: block) do
    prelude =
      quote do
        unquote(block)
      end

    postlude =
      quote unquote: false do
        app_options = @app_options
        lib_deps = @lib_deps |> Enum.reverse()
        mix_deps = @mix_deps |> Enum.reverse()
        modifiers = @modifiers |> Enum.reverse()
        files = @files |> Enum.reverse()
        directories = @directories |> Enum.reverse()
        templates = @templates |> Enum.reverse()
        preserve = @preserve |> Enum.reverse()

        def __app_options__, do: unquote(Macro.escape(app_options))
        def __lib_deps__, do: unquote(Macro.escape(lib_deps))
        def __mix_deps__, do: unquote(Macro.escape(mix_deps))
        def __modifiers__, do: unquote(Macro.escape(modifiers))
        def __files__, do: unquote(Macro.escape(files))
        def __directories__, do: unquote(Macro.escape(directories))
        def __templates__, do: unquote(Macro.escape(templates))
        def __preserve__, do: unquote(Macro.escape(preserve))
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  @doc """
  Specify various rules to apply to the ejected app `lib/` directory files. These are the
  same "file rules" that can be applied to a lib dep. See `Eject.Rules` for a full
  list of options.
  """
  defmacro app(opts) do
    quote do
      Module.put_attribute(__MODULE__, :app_options, unquote(opts))
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
  defmacro lib(name, opts) do
    quote do
      Eject.__lib__(__MODULE__, unquote(name), unquote(opts))
    end
  end

  @doc false
  def __lib__(mod, name, opts) when is_atom(name) and is_list(opts) do
    lib_dep =
      Eject.LibDep.new!(%{
        name: name,
        lib_deps: opts |> Keyword.get(:lib_deps, []) |> List.wrap(),
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap(),
        always: Keyword.get(opts, :always, false),
        file_rules: Eject.Rules.new(opts)
      })

    Module.put_attribute(mod, :lib_deps, lib_dep)
  end

  @doc """
  Options include:
    - `mix_deps: atom | [atom]` - other mix dependencies that the mix requires (i.e. nested dependencies).
      Note that each nested dependency itself must also have an entry on the "top" level of the list.
  """
  defmacro mix(name, opts) do
    quote do
      Eject.__mix__(__MODULE__, unquote(name), unquote(opts))
    end
  end

  @doc false
  def __mix__(mod, name, opts) when is_atom(name) and is_list(opts) do
    mix_dep =
      Eject.MixDep.new!(%{
        name: name,
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap()
      })

    Module.put_attribute(mod, :mix_deps, mix_dep)
  end

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
  defmacro modify(path_or_regex, file, app, do: block) do
    line = __ENV__.line
    fn_name = String.to_atom("modify_#{line}")

    quote do
      Eject.__register_modifier__(__MODULE__, unquote(path_or_regex), unquote(fn_name))
      def unquote(fn_name)(unquote(file), unquote(app)), do: unquote(block)
    end
  end

  def __register_modifier__(mod, path_or_regex, fn_name) do
    Module.put_attribute(mod, :modifiers, {path_or_regex, {mod, fn_name}})
  end

  defmacro file(path) do
    quote do
      Module.put_attribute(__MODULE__, :files, unquote(path))
    end
  end

  defmacro dir(path) do
    quote do
      Module.put_attribute(__MODULE__, :directories, unquote(path))
    end
  end

  defmacro template(path) do
    quote do
      Module.put_attribute(__MODULE__, :templates, unquote(path))
    end
  end

  defmacro preserve(path) do
    quote do
      Module.put_attribute(__MODULE__, :preserve, unquote(path))
    end
  end

  @doc """
  Lists additional 'base files' to be ejected.

  The following files are automatically ejected and should not be listed:
    - files in the lib directory of the ejected app
    - files packaged in a `lib` directory (refer to the `lib_deps` callback for details)
  """
  @callback base_files(Eject.App.t()) :: [Path.t() | {:dir | :template | :binary, Path.t()}]

  @doc """
  Returns a keyword list of additional key value pairs available to _all_ ejectable apps.

  As an example, you may want to set the theme based on the name of the ejectable app.
  In this case, add an 'extra' entry called 'theme', which will then be available through the
  app struct:

      def extra(app) do
        theme =
          case app.name.snake do
            "work_" <> _ -> :work
            "personal_" <> _ -> :personal
            _ -> raise "App name must start with Work or Personal to derive theme."
          end

        [theme: theme]
      end

  For app specific pairs, use the `extra` option in the app's manifest. See `Eject.Manifest`.
  """
  @callback extra(Eject.App.t()) :: keyword

  @type prepare_opt :: {:destination, String.t()}

  @doc """
  Returns a list of ejectable application names.

  Identified by the existence of a `lib/<my_app>/ejector.exs` file.

  ### Examples

      $ fd eject.exs
      lib/tweeter/eject.exs
      lib/trillo/eject.exs
      lib/hatmail/eject.exs

      iex> ejectables()
      ["Tweeter", "Trillo", "Hatmail"]

  """
  @spec ejectables :: [String.t()]
  def ejectables do
    "lib/*/eject.exs"
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.dirname() |> Path.basename() |> Macro.camelize()))
    |> Enum.sort()
  end

  @spec ejectable_apps :: [Eject.App.t()]
  def ejectable_apps do
    for name <- ejectables() do
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      name = Module.concat("Elixir", name)
      prepare(%{name: name, opts: []})
    end
  end

  @doc """
  Prepares the `t:Eject.App.t/0` struct with all information needed for ejection.

  When ejecting an app, this step runs prior to the actual `eject/1` process,
  allowing the user to see pertinent information about what decisions will be made
  during ejection: (e.g. which dependencies will be included, where on
  disk the ejected app will be written, etc.). If there is a mistake, the user will
  have a chance to abort before performing a potentially destructive action.
  """
  @spec prepare(init :: %{name: atom, opts: [prepare_opt]}) :: Eject.App.t()
  def prepare(%{name: name, opts: opts}) do
    if not is_atom(name) do
      raise ArgumentError,
        message:
          "🤖 Please pass in a module name corresponding to a directory in `lib` containing an `eject.exs` file. E.g. Tweeter (received #{inspect(name)})"
    end

    project = Eject.Project.build()

    project
    |> Eject.Manifest.eval_and_parse(Macro.underscore(name))
    |> Eject.App.new!(project, name, opts)
  end

  @doc """
  Ejects an app. That is, deletes the files in the destination and copies a fresh
  set of files for that app.
  """
  def eject(app) do
    clear_destination(app)
    Logger.info("📂 #{app.destination}")
    File.mkdir_p!(app.destination)

    for ejectable <- Eject.File.all_for_app(app) do
      Logger.info("💾 [#{ejectable.type}] #{ejectable.destination}")
      Eject.File.eject!(ejectable, app)
    end

    # remove mix deps that are not needed for this project from mix.lock
    System.cmd("mix", ["deps.clean", "--unlock", "--unused"], cd: app.destination)
    System.cmd("mix", ["format"], cd: app.destination)
  end

  # Clear the destination folder where the app will be ejected.
  def clear_destination(app) do
    if File.exists?(app.destination) do
      preserve = app.project.module.__preserve__()
      preserve = [".git", "deps", "_build" | preserve]

      app.destination
      |> File.ls!()
      |> Enum.reject(&(&1 in preserve))
      |> Enum.each(fn file_or_folder ->
        path = Path.join(app.destination, file_or_folder)
        Logger.info("💥 #{path}")
        File.rm_rf(path)
      end)
    end
  end
end
