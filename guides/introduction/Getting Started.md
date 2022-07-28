# Getting Started

## Adding Eject to an Application

Add `:eject` as a dependency in `mix.exs` and wrap your endir dependency list in
`# <eject:deps>` and `# </eject:deps>` comments, like this:


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

When using `Eject`, you must have a Plan module. It contains all of the details
(the "plan") for how the ejector should behave whenever you tell it to eject a
specific application.

```elixir
defmodule MyApp.Eject.Plan do
  use Eject.Plan, templates: "lib/my_app/eject/templates"
end
```

You can name the module whatever you like, but we suggest putting it in `lib/my_app/eject/plan.ex`
and specifying the templates directory alongside it in `lib/my_app/eject/templates`.

Then, in `config/config.exs` put the following line. (Changing the `plan` value
to match the name of your `Plan` module above.)

```elixir
config :ucbi_dev, Eject, plan: MyApp.Eject.Plan
```

## Ejecting an Application

To eject an application, run

```
mix eject MyApplicationName
```
