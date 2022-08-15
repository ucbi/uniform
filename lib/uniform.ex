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
  - [Uniform Manifests](uniform-manifests-uniform-exs.html)
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
  an Elixir application. In summary, you'll need to:

  1. Add the dep in `mix.exs`
  2. Add a [Blueprint](Uniform.Blueprint.html) module to your project
  3. Add configuration to identify the Blueprint module
  4. Add `uniform.exs` manifests to each Ejectable App
  5. Fill out the Blueprint so all the necessary files get ejected

  > #### Uniform ❤️ Automation {: .tip}
  >
  > Uniform is about powering up developers by automating repetitive work.
  >
  > With that in mind, we recommend using Continuous Integration (CI) tools to
  > [automate the process of committing code to ejected
  > repos](auto-updating-ejected-codebases.html).

  """

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

        Did you forget to run this command?

            mix uniform.gen.app #{name}

        """
    end

    Mix.Task.run("compile", [])
    config = Uniform.Config.build()
    manifest = Uniform.Manifest.eval_and_parse(config, Macro.underscore(name))
    Uniform.App.new!(config, manifest, name, opts)
  end
end
