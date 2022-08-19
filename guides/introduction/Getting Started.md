# Getting Started

## Add Uniform to mix.exs

Add `:uniform` as a dependency in `mix.exs`.

```elixir
defp deps do
  [
    {:uniform, "~> 0.5.1"}
  ]
end
```

## Run `mix uniform.init`

After adding `:uniform` to `mix.exs` and running `mix deps.get`, run

```bash
mix uniform.init
```

This will [Create a Blueprint module](#create-a-blueprint-module) and add
[Configuration](#configuration), which you can do manually if you'd rather by
following the steps below.

### Create a Blueprint module

If you opted out of running `mix uniform.init`, create a
[Blueprint](Uniform.Blueprint.html) module. This is the central file you'll use
to tell Uniform which files to copy when running `mix uniform.eject`.

To start, you can create an empty Blueprint like this.

```elixir
defmodule MyApp.Uniform.Blueprint do
  use Uniform.Blueprint
end
```

You can name the module whatever you like, but we suggest putting it in
`lib/my_app/uniform/blueprint.ex`.

### Configuration

If you opted out of running `mix uniform.init`, add the following line to
`config/config.exs`. (Changing the `blueprint` value to match the name of your
Blueprint module above.)

```elixir
config :my_app, Uniform, blueprint: MyApp.Uniform.Blueprint
```

You can also optionally set a default `destination` for ejected apps.

```elixir
# With optional :destination
config :my_app, Uniform,
  blueprint: MyApp.Uniform.Blueprint,
  destination: "/Users/me/ejected"
```

If `destination` is ommitted, the default is one level up from the Base
Project's root folder. The `--destination` option of `mix uniform.eject` takes
precedence and overrides both of these behaviors.

## Add Uniform Manifests

> #### Skip this step if you have no apps yet. {: .tip}
>
> If you're setting up a brand new project, skip to [Build the
> Blueprint](#build-the-blueprint).
>
> When you add [Ejectable Apps](how-it-works.html#ejectable-apps) in your
> project, you'll need to come back to this step.

Put a `uniform.exs` file inside each directory in `lib` that represents an
Ejectable App. You can do so with this command:

```bash
mix uniform.gen.app my_app_name
```

It creates an empty manifest with code comments to help you start. If you want
to create the file manually instead, start with a barebones file that contains
an empty list:

```elixir
# lib/my_app_name/uniform.exs
[]
```

The [Uniform Manifests](uniform-manifests-uniform-exs.html) guide explains how
to use this file.

At this point you should be able to run:

```bash
mix uniform.eject my_app_name
```

And it will create a standalone codebase for the app. However, it probably
won't contain the files needed to run locally or be deployed.

This leads us to the final step of **Building the Blueprint**.

## Build the Blueprint

> Read the documentation for [Uniform.Blueprint](Uniform.Blueprint.html) for
> the full range of features to build out your Blueprint module.

The Blueprint module is central for configuring which files are ejected during
`mix uniform.eject`.

Since each Elixir project is different, **it is up to you** to determine which
files need to be ejected in your project to emit a working application.

> #### Are you building Phoenix apps? {: .tip}
>
> The [Setting up a Phoenix project](./setting-up-a-phoenix-project.html) guide
> contains details and examples for building your Blueprint.

An example barebones Blueprint might look like this.

```elixir
defmodule MyApp.Uniform.Blueprint do
  use Uniform.Blueprint

  base_files do
    file "lib/my_app/application.ex"
    file "lib/my_app_web/endpoint.ex"
    cp_r "assets"
    template "config/runtime.exs"
  end

  deps do
    always do
      mix :phoenix
      mix :phoenix_html

      lib :utilities
    end

    lib :my_data_graph do
      mix_deps [:absinthe]
    end
  end
end
```
