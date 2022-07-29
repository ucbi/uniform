# Getting Started

## Adding Eject to an Application

Add `:eject` as a dependency in `mix.exs` and wrap your endir dependency list in
`# <eject:deps>` and `# </eject:deps>` comments, like this.


```elixir
defp deps do
  # <eject:deps>
  [
    {:eject, "~> 0.1.0"},
    {:other_dep, ...},
    ...
  ]
  # </eject:deps>
end
```

## The Plan module

Create a [Plan](Eject.Plan.html) module. It contains all of the details (the
"plan") for how the ejector should behave whenever you tell it to eject a
specific application.

```elixir
defmodule MyApp.Eject.Plan do
  use Eject.Plan, templates: "lib/my_app/eject/templates"
end
```

You can name the module whatever you like, but we suggest putting it in `lib/my_app/eject/plan.ex`
and specifying the templates directory alongside it in `lib/my_app/eject/templates`.

## Configuration

In `config/config.exs` put the following line. (Changing the `plan` value to
match the name of your Plan module name above.)

```elixir
config :my_app, Eject, plan: MyApp.Eject.Plan
```

You can also optionally set a default `destination` for ejected apps.

```elixir
# With optional :destination
config :my_app, Eject,
  plan: MyApp.Eject.Plan,
  destination: "/Users/me/ejected"
```

If `destination` is ommitted, the default is one level up from the Base
Project's root folder. The `--destination` option of `mix eject` takes
precedence and overrides both of these behaviors.

## Ejecting an Application

Designate all `lib/` directories that represent an ejectable application by
placing an `eject.exs` manifest file into each directory. You can start with a
barebones manifest that contains an empty list.

```elixir
# lib/my_application_name/eject.exs
[]
```

> #### More on eject.exs {: .info}
>
> See [eject.exs Options](./how-it-works.html#eject-exs-options)
> for an explanation of supported options.

Then run

```bash
mix eject MyApplicationName
```
