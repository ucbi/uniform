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
      import Eject.App, only: [depends_on?: 3]
      def __templates__, do: unquote(templates)
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
  Lists all available local lib (not hex) dependencies an ejected app may use.

  Lib dependencies are identified by an atom that corresponds to the lib directory. For
  example, `:my_cool_utilities` ejects _all_ files in the `lib/my_cool_utilities` directory.
  If additional files from a different directory are needed, use the `associated_files` option.
  If you only need selected files from the `lib` directory, use the `only` option.

  Once listed, each ejectable app may elect to include the lib dependency by adding it
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
  @callback lib_deps :: [LibDep.name() | {LibDep.name(), keyword}]

  @doc """
  Lists mix.exs dependencies NOT to always include. In other words, mix dependencies that
  may optionally be excluded.

  Unlike `lib_deps`, which are _excluded_ by default, `mix_deps` are _included_ by default.
  As such, the mix dependency must be added to this list in order to allow each ejectable app
  to exclude the dependency.

  Once listed, each ejectable app may elect to exclude (i.e. don't eject) the mix dependency
  by adding it to its `Eject` manifest (see `Eject.Manifest`).

  Options include:
    - `mix_deps: atom | [atom]` - other mix dependencies that the mix requires (i.e. nested dependencies).
      Note that each nested dependency itself must also have an entry on the "top" level of the list.
  """
  @callback mix_deps :: [MixDep.name() | {MixDep.name(), keyword}]

  @doc """
  Returns a list of tuples, with each tuple containing a file or regex pattern and a transformation function.

  ### Example

      [
        {
          ~r/lib\/.+_(worker|cron).ex/,
          &Modify.worker_cron/2
        },
        {
          "lib/my_app_web/router.ex",
          &Modify.router/2
        }
      ]

  """
  @callback modify :: [{Path.t() | Regex.t(), (String.t(), Eject.App.t() -> String.t())}]

  @doc """
  Lists various options or settings that control the ejection process, including:

    - `preserve` - Preserve (i.e. do not delete) the specified root-level files/directories
      when clearing ejection destination.
    - `ejected_app` - Specify various rules to apply to the ejected app `lib/` directory files. These
    are the same "file rules" that can be applied to a lib dep. See `Eject.Rules` for a full list of options.

  """
  @callback options(Eject.App.t()) :: keyword

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

    project = project()

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
    IO.write(IO.ANSI.clear_line() <> "\r📂 #{app.destination}")
    File.mkdir_p!(app.destination)

    for ejectable <- Eject.File.all_for_app(app) do
      IO.write(IO.ANSI.clear_line() <> "\r💾 [#{ejectable.type}] #{ejectable.destination}")
      Eject.File.eject!(ejectable, app)
    end

    IO.puts("")
    # remove mix deps that are not needed for this project from mix.lock
    System.cmd("mix", ["deps.clean", "--unlock", "--unused"], cd: app.destination)
    System.cmd("mix", ["format"], cd: app.destination)
    IO.puts("")
    IO.puts("✅ #{app.name.pascal} ejected to #{app.destination}")
  end

  # Clear the destination folder where the app will be ejected.
  def clear_destination(app) do
    if File.exists?(app.destination) do
      preserve = Keyword.get(app.project.module.options(app), :preserve, [])
      preserve = [".git", "deps", "_build" | preserve]

      app.destination
      |> File.ls!()
      |> Enum.reject(&(&1 in preserve))
      |> Enum.each(fn file_or_folder ->
        path = Path.join(app.destination, file_or_folder)
        IO.write(IO.ANSI.clear_line() <> "\r💥 #{path}")
        File.rm_rf(path)
      end)
    end
  end

  defp project do
    base_app = Keyword.fetch!(Mix.Project.config(), :app)
    Eject.Project.from_config_key(base_app)
  end
end
