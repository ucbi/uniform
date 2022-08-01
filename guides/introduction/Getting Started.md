# Getting Started

## Add Eject to mix.exs

Add `:eject` as a dependency in `mix.exs` and wrap your entire dependency list in
`# <eject:deps>` and `# </eject:deps>` comments, like this.


```elixir
defp deps do
  # <eject:deps>
  [
    {:eject, "~> 0.1.0"},
    ...
  ]
  # </eject:deps>
end
```

## Create a Blueprint module

Next, create a [Blueprint](Eject.Blueprint.html) module. It will contain all of
the details for how `mix eject` should behave whenever you tell it to eject a
specific application.

```elixir
defmodule MyApp.Eject.Blueprint do
  use Eject.Blueprint, templates: "lib/my_app/eject/templates"
end
```

You can name the module whatever you like, but we suggest putting it in
`lib/my_app/eject/blueprint.ex` and specifying the templates directory alongside it
in `lib/my_app/eject/templates`.

## Configuration

In `config/config.exs` put the following line. (Changing the `blueprint` value to
match the name of your Blueprint module name above.)

```elixir
config :my_app, Eject, blueprint: MyApp.Eject.Blueprint
```

You can also optionally set a default `destination` for ejected apps.

```elixir
# With optional :destination
config :my_app, Eject,
  blueprint: MyApp.Eject.Blueprint,
  destination: "/Users/me/ejected"
```

If `destination` is ommitted, the default is one level up from the Base
Project's root folder. The `--destination` option of `mix eject` takes
precedence and overrides both of these behaviors.

## Add Eject Manifests

Designate all `lib` directories that represent an [Ejectable
App](how-it-works.html#what-is-an-ejectable-app) by placing an `eject.exs`
manifest file into each directory. You can start with a barebones manifest that
contains an empty list.

```elixir
# lib/my_application_name/eject.exs
[]
```

Once you start structuring your project for the Eject System, you'll add
[Lib](dependencies.html#lib-dependencies) and
[Mix](dependencies.html#mix-dependencies) Dependencies in this file.

```elixir
[
  lib_deps: [:my_data_source, :utilities],
  mix_deps: [:csv, :chromic_pdf]
]
```

> #### More on eject.exs {: .info}
>
> See [eject.exs Options](./how-it-works.html#eject-exs-options)
> for an exblueprintation of supported options.

## Ejecting an Application

At this point, you should be able to run

```bash
mix eject MyApplicationName
```

And be able to successfully create an ejected codebase. However, it will
probably lack critical code that is needed to run properly.

This leads us to the final step of **Building a Blueprint**.

## Build the Blueprint

> Read the documentation for [Eject.Blueprint](Eject.Blueprint.html) for the full range
> of features to build out your Blueprint module.

Since each Elixir application is different, **it is up to you to determine which files need to be ejected** to make `mix eject` emit a working application.

> #### Using Phoenix? {: .tip}
>
> We recommend developers building Phoenix projects read about [the Eject
> System](how-it-works.html), then consult the how-to guide for [Setting up a
> Phoenix Project](./setting-up-a-phoenix-project.html).

An example barebones Blueprint might look like this.

```elixir
defmodule MyApp.Eject.Blueprint do
  use Eject.Blueprint

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
