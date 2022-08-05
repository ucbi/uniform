defmodule Uniform do
  @moduledoc """
  The Uniform System is an architecture for maintaining multiple Elixir apps
  from a single Elixir project in a way that minimizes duplicate work and
  maximizes sharing capabilities.

  It's like a monolith. But unlike a monolith, the apps can be "ejected" into
  separate codebases that only contain the code needed by each app.

  ## Recommended Guides

  In order to understand and use this library, we heavily recommend reading the
  following guides:

  - [The Uniform System: How It Works](how-it-works.html)
  - [Dependencies](dependencies.html)
  - [Code Transformations](code-transformations.html)

  The [Setting up a Phoenix project](setting-up-a-phoenix-project.html) guide
  is recommended if you're building Phoenix apps.

  ## Usage

  ```bash
  mix uniform.eject Tweeter
  ```

  Read about [the Uniform System](how-it-works.html) for details about how it
  works.

  ## Installation

  Consult the [Getting Started](getting-started.html) guide to add `Uniform` to
  an Elixir application.

  In summary, you'll need to:

  1. Add the dep in `mix.exs`: `{:uniform, "~> 0.1.0"}`
  2. Add a [Blueprint](Uniform.Blueprint.html) module to your project
  3. Configure your Elixir app to point to the Blueprint module
  4. Add `uniform.exs` manifests to each Ejectable Application
  5. Add to the Blueprint module all the files necessary to eject a working
     application

  """

  require Logger

  @typep prepare_opt :: {:destination, String.t()}

  @doc """
       Returns a list of ejectable application names.

       Identified by the existence of a `lib/<my_app>/uniform.exs` file.

       ### Examples

           $ fd uniform.exs
           lib/tweeter/uniform.exs
           lib/trillo/uniform.exs
           lib/hatmail/uniform.exs

           iex> ejectables()
           ["Tweeter", "Trillo", "Hatmail"]

       """ && false
  @spec ejectables :: [String.t()]
  def ejectables do
    "lib/*/uniform.exs"
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.dirname() |> Path.basename() |> Macro.camelize()))
    |> Enum.sort()
  end

  @doc "Return a list of all ejectable `%App{}`s" && false
  @spec ejectable_apps :: [Uniform.App.t()]
  def ejectable_apps do
    for name <- ejectables() do
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      name = Module.concat("Elixir", name)
      prepare(%{name: name, opts: []})
    end
  end

  @doc """
       Prepares the `t:Uniform.App.t/0` struct with all information needed for ejection.

       When ejecting an app, this step runs prior to the actual `eject/1` process,
       allowing the user to see pertinent information about what decisions will be made
       during ejection: (e.g. which dependencies will be included, where on
       disk the ejected app will be written, etc.). If there is a mistake, the user will
       have a chance to abort before performing a potentially destructive action.
       """ && false
  @spec prepare(init :: %{name: atom, opts: [prepare_opt]}) :: Uniform.App.t()
  def prepare(%{name: name, opts: opts}) do
    if not is_atom(name) do
      raise ArgumentError,
        message:
          "🤖 Please pass in a module name corresponding to a directory in lib/ containing an `uniform.exs` file. E.g. Tweeter (received #{inspect(name)})"
    end

    # ensure the name was passed in CamelCase format; otherwise subtle bugs happen
    unless inspect(name) =~ ~r/^[A-Z][a-zA-Z0-9]*$/ do
      raise ArgumentError,
        message: """
        The name must correspond to a directory in lib/, in CamelCase format.

        For example, to eject `lib/my_app`, do:

            mix uniform.eject MyApp

        """
    end

    Mix.Task.run("compile", [])

    config = Uniform.Config.build()
    manifest = Uniform.Manifest.eval_and_parse(config, Macro.underscore(name))
    Uniform.App.new!(config, manifest, name, opts)
  end

  @doc """
       Ejects an app. That is, deletes the files in the destination and copies a fresh
       set of files for that app.
       """ && false
  def eject(app) do
    clear_destination(app)
    Logger.info("📂 #{app.destination}")
    File.mkdir_p!(app.destination)

    for ejectable <- Uniform.File.all_for_app(app) do
      Logger.info("💾 [#{ejectable.type}] #{ejectable.destination}")
      Uniform.File.eject!(ejectable, app)
    end

    # remove mix deps that are not needed for this project from mix.lock
    System.cmd("mix", ["deps.clean", "--unlock", "--unused"], cd: app.destination)
    System.cmd("mix", ["format"], cd: app.destination)
  end

  @doc "Clear the destination folder where the app will be ejected." && false
  def clear_destination(app) do
    if File.exists?(app.destination) do
      {:module, _} = Code.ensure_loaded(app.internal.config.blueprint)

      preserve = app.internal.config.blueprint.__preserve__()
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
