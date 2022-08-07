# Getting Started

## Add Uniform to mix.exs

Add `:uniform` as a dependency in `mix.exs` and wrap your entire dependency
list in `# uniform:deps` and `# /uniform:deps` comments, like this.


```elixir
defp deps do
  # uniform:deps
  [
    {:uniform, "~> 0.1.1"},
    ...
  ]
  # /uniform:deps
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

Next, create a [Blueprint](Uniform.Blueprint.html) module. It will contain all
of the details for how `mix uniform.eject` should behave whenever you tell it
to eject a specific application.

```elixir
defmodule MyApp.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "lib/my_app/uniform/templates"
end
```

You can name the module whatever you like, but we suggest putting it in
`lib/my_app/uniform/blueprint.ex` and specifying the templates directory
alongside it in `lib/my_app/uniform/templates`.

### Configuration

In `config/config.exs` put the following line. (Changing the `blueprint` value
to match the name of your Blueprint module name above.)

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

Designate all `lib` directories that represent an [Ejectable
App](how-it-works.html#ejectable-apps) by placing an `uniform.exs`
manifest file into each directory.

You can do so with `mix uniform.gen.app`, which creates an empty manifest
containing code comments to help you start.

```bash
mix uniform.gen.app my_application_name
```

Or, if you want to do this manually, you can start with a barebones manifest
that contains an empty list.

```elixir
# lib/my_application_name/uniform.exs
[]
```

Once you start structuring your project for Uniform, you'll add
[Lib](dependencies.html#lib-dependencies) and
[Mix](dependencies.html#mix-dependencies) Dependencies in this file.

```elixir
[
  lib_deps: [:my_data_source, :utilities],
  mix_deps: [:csv, :chromic_pdf]
]
```

> #### More on uniform.exs {: .info}
>
> See [uniform.exs Options](./how-it-works.html#uniform-exs-options) for an
> explanation of supported options.

## Ejecting an Application

At this point, you should be able to run

```bash
mix uniform.eject MyApplicationName
```

And be able to successfully create an ejected codebase. However, it will
probably lack critical code that is needed to run properly.

This leads us to the final step of **Building a Blueprint**.

## Build the Blueprint

> Read the documentation for [Uniform.Blueprint](Uniform.Blueprint.html) for
> the full range of features to build out your Blueprint module.

Since each Elixir application is different, **it is up to you to determine
which files need to be ejected** to make `mix uniform.eject` emit a working
application.

> #### Are you building Phoenix apps? {: .tip}
>
> We recommend developers building Phoenix applications read the [How It
> Works](how-it-works.html) guide, then consult the how-to guide for [Setting
> up a Phoenix Project](./setting-up-a-phoenix-project.html).

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
