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

  ### Marking a `lib/` Directory as an Ejectable App

  To designate a directory in `lib/` as an ejectable app, place a file
  called `eject.exs` directly inside that directory.

  The `eject.exs` manifest specifies required dependencies and configuration values:
    - `mix_deps` - mix dependencies; each must exist in `mix.exs`.
    - `lib_deps` - lib dependencies; each must exist as a folder in `lib/`.
    - `extra` - additional key value pairs specific to the ejectable app. For 'global' values available
      to _all_ ejectable apps, use the `c:Eject.Plan.extra/1` callback implementation.

  Required for each ejectable app.

      # Example `eject.exs`
      [
        mix_deps: [:ex_aws_s3],
        lib_deps: [:my_utilities],
        extra: [
          sentry: [...],
          deployment: [
            target: :heroku,
            options: [...],
              buildpacks: [...],
              addons: [...],
              domains: [...]
          ]
        ]
      ]

  ### Usage

      $ mix eject Tweeter

  See `Mix.Tasks.App.Eject` for details.

  """

  require Logger

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

    Mix.Task.run("compile", [])

    config = Eject.Config.build()
    manifest = Eject.Manifest.eval_and_parse(config, Macro.underscore(name))
    Eject.App.new!(config, manifest, name, opts)
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
      preserve =
        for {:preserve, filename} <- app.config.plan.__eject__(app) do
          filename
        end

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
