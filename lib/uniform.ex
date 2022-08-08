defmodule Uniform do
  @moduledoc """
  > Write less boilerplate and reuse more code in your portfolio of Elixir apps

  With Uniform, developers maintain multiple Elixir apps inside a Base Project:
  a "monolith" containing every app. Before deployment, the apps are "ejected"
  into separate codebases containing only the code needed by each app.

  The entire process is automated, so there's much less work required to start
  a new app or share capabilities between apps.

  ## Recommended Guides

  In order to understand and use this library, we heavily recommend reading the
  following guides:

  - [How It Works](how-it-works.html)
  - [Dependencies](dependencies.html)
  - [Code Transformations](code-transformations.html)

  The [Setting up a Phoenix project](setting-up-a-phoenix-project.html) guide
  is recommended if you're building Phoenix apps.

  ## Usage

  ```bash
  mix uniform.eject tweeter
  ```

  ## Installation

  Consult the [Getting Started](getting-started.html) guide to add Uniform to
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
  Returns a list of all [Ejectable App](how-it-works.html#ejectable-apps) names
  in your Base Project.

  ### Examples

  ```bash
  $ fd uniform.exs
  lib/tweeter/uniform.exs
  lib/trillo/uniform.exs
  lib/hatmail/uniform.exs
  ```

      iex> ejectable_app_names()
      ["tweeter", "trillo", "hatmail"]

  """
  @spec ejectable_app_names :: [String.t()]
  def ejectable_app_names do
    "lib/*/uniform.exs"
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.dirname() |> Path.basename()))
    |> Enum.sort()
  end

  @doc """
  Return a list of all [Ejectable Apps](how-it-works.html#ejectable-apps) in
  your Base Project as `Uniform.App` structs.

  ### Example

  ```bash
  $ fd uniform.exs
  lib/tweeter/uniform.exs
  lib/trillo/uniform.exs
  lib/hatmail/uniform.exs
  ```

      iex> ejectable_apps()
      [
        #Uniform.App<
          extra: [...],
          name: %{camel: "Tweeter", hyphen: "tweeter", module: Tweeter, underscore: "tweeter"},
          ...
        >,
        #Uniform.App<
          extra: [...],
          name: %{camel: "Trillo", hyphen: "trillo", module: Trillo, underscore: "trillo"},
          ...
        >,
        #Uniform.App<
          extra: [...],
          name: %{camel: "Hatmail", hyphen: "hatmail", module: Hatmail, underscore: "hatmail"},
          ...
        >
      ]

  """
  @spec ejectable_apps :: [Uniform.App.t()]
  def ejectable_apps do
    for name <- ejectable_app_names() do
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
    # ensure the name was passed in under_score format; otherwise subtle bugs happen
    unless name in Uniform.ejectable_app_names() do
      raise ArgumentError,
        message: """
        The name must correspond to a directory in lib, in under_score format.

        For example, to eject `lib/my_app`, do:

            mix uniform.eject my_app

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
