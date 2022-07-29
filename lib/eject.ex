defmodule Eject do
  @moduledoc """
  A system for maintaining multiple homogenous Elixir apps from a single Elixir
  project in a way that minimizes duplicate work.

  With `Eject`, the apps are maintained together in development. But when you're
  ready to deploy them, they're "ejected" out into a separate codebase that
  only contains the code needed by the app.

  ## Usage

  ```bash
  mix eject Tweeter
  ```

  See `mix eject` for details.

  ## Installation

  To set up a project for `Eject`, you need to:

  1. Add the dep in `mix.exs`: `{:eject, "~> 0.1.0"}`
  2. Add a [Plan](Eject.Plan) module to your project
  3. Configure your Elixir app to point to the Plan module
  4. Add `eject.exs` manifests to each Ejectable Application

  For more details about each step, consult the [Getting
  Started](getting-started.html) guide.

  ## The Eject System

  `Eject` is not just a library, but a whole system for structuring
  applications.
  """

  require Logger

  @typep prepare_opt :: {:destination, String.t()}

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

       """ && false
  @spec ejectables :: [String.t()]
  def ejectables do
    "lib/*/eject.exs"
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.dirname() |> Path.basename() |> Macro.camelize()))
    |> Enum.sort()
  end

  @doc "Return a list of all ejectable `%App{}`s" && false
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
       """ && false
  @spec prepare(init :: %{name: atom, opts: [prepare_opt]}) :: Eject.App.t()
  def prepare(%{name: name, opts: opts}) do
    if not is_atom(name) do
      raise ArgumentError,
        message:
          "🤖 Please pass in a module name corresponding to a directory in lib/ containing an `eject.exs` file. E.g. Tweeter (received #{inspect(name)})"
    end

    # ensure the name was passed in CamelCase format; otherwise subtle bugs happen
    unless inspect(name) =~ ~r/^[A-Z][a-zA-Z0-9]*$/ do
      raise ArgumentError,
        message: """
        The name must correspond to a directory in lib/, in CamelCase format.

        For example, to eject `lib/my_app`, do:

            mix eject MyApp

        """
    end

    Mix.Task.run("compile", [])

    config = Eject.Config.build()
    manifest = Eject.Manifest.eval_and_parse(config, Macro.underscore(name))
    Eject.App.new!(config, manifest, name, opts)
  end

  @doc """
       Ejects an app. That is, deletes the files in the destination and copies a fresh
       set of files for that app.
       """ && false
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

  @doc "Clear the destination folder where the app will be ejected." && false
  def clear_destination(app) do
    if File.exists?(app.destination) do
      Code.ensure_loaded!(app.internal.config.plan)

      preserve =
        if function_exported?(app.internal.config.plan, :__eject__, 1) do
          for {:preserve, filename} <- app.internal.config.plan.__eject__(app), do: filename
        else
          []
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
