# Setting up a Phoenix project

> This guide assumes that you're familiar with [The Eject
> System](how-it-works.html) and have gone through the [Getting
> Started](#getting-started.html) guide.

With the Eject System, teams can save dozens of hours of time setting up a
Phoenix codebase's structure to match existing ones.

This guide walks through a typical process for setting up an Elixir Phoenix
project with `Eject`.

## The Value Proposition

Imagine creating an entire new application simply by adding a Router and a
single LiveView to an existing Elixir project.

This is in fact the vision that drove the creation of `Eject`. The overhead of
experimenting with new apps becomes extremely low, incentivizing the team to
try out ideas without being inhibited by initial setup time.

## Setting up your Plan module

Below is an example [Plan](Eject.Plan.html) module for ejecting the files
common to Phoenix applications.

```elixir
defmodule MyBaseApp.Eject.Plan do
  use Eject.Plan, templates: "lib/my_base_app/eject/templates"

  eject(app) do
    cp_r "assets"
    cp_r "priv/static"

    file "lib/my_base_app_web.ex"
    file Path.wildcard("config/**/*.exs")
    file Path.wildcard("test/support/*_case.ex")
  end

  deps do
    # Always eject the `my_base_app` and `my_base_app_web` libraries.
    #
    # Their paths and file contents will replace my_base_app with the ejected
    # app name automatically.
    always do
      lib :my_base_app do
        only [
          "lib/my_base_app/application.ex",
          "lib/my_base_app/repo.ex"
        ]

        # `match_dot: true` so that we eject `priv/repo/.formatter.exs`
        file Path.wildcard("priv/repo/**/*.exs", match_dot: true)
      end

      lib :my_base_app_web do
        only [
          "lib/my_base_app_web/endpoint.ex",
          "lib/my_base_app_web/gettext.ex",
          "lib/my_base_app_web/router.ex",
          "lib/my_base_app_web/telemetry.ex",
          "lib/my_base_app_web/channels/user_socket.ex",
          "lib/my_base_app_web/templates/layout/app.html.heex",
          "lib/my_base_app_web/templates/layout/live.html.heex"
          "lib/my_base_app_web/templates/layout/root.html.heex",
          "lib/my_base_app_web/views/error_helpers.ex",
          "lib/my_base_app_web/views/error_view.ex",
          "lib/my_base_app_web/views/layout_view.ex"
        ]
      end
    end
  end
end
```

Let's walk through it step by step.

## The `eject` section

```elixir
eject(app) do
  cp_r "assets"
  cp_r "priv/static"

  file "lib/my_base_app_web.ex"
  file Path.wildcard("config/**/*.exs")
  file Path.wildcard("test/support/*_case.ex")
end
```

In the [eject](Eject.Plan.html#eject/2) block, we specify files that should _always_
be ejected in every app. Phoenix apps will typically have CSS and JS assets in
the `assets` directory. They'll also have static files to be served as-is in
`priv/static`. Some of these files are binary (non-text) files, and we assume
none of them need to pass through the [Code
Transformation](code-transformations.html) phase. That's why the first two
lines are included.

```elixir
cp_r "assets"
cp_r "priv/static"
```

Note that `cp_r` instructs `mix eject` to copy all the directory contents
(using `File.cp_r!/3`).

Phoenix apps typically have an `Web` module which is used to construct
Controllers, Views, Routers, and LiveViews. Since this file is typically
in `lib/` directly (and not in a sub-directory of `lib/`), we include it
here in the `eject` block.

```elixir
file "lib/my_base_app_web.ex"
```

We also proceed with the assumption that the ejected app will need the
Base Project's configuration files.

```elixir
file Path.wildcard("config/**/*.exs")
```

> #### Use Code Fences for config files {: .tip}
>
> If there are areas of the configuration files that you want to modify, such
> as excluding configuration for a dependency that isn't included, use [Code
> Fences](code-transformations.html#code-fences).

## The `deps` section

In the `deps` section, we put both `lib :my_base_app` and `lib
:my_base_app_web` inside `always do` so that their contents are
always ejected without having to specify `lib_deps: [:my_base_app,
:my_base_app_web]` in the `eject.exs` manifest of every app.

```elixir
deps do
  always do
    lib :my_base_app do
      # ...
    end

    lib :my_base_app_web do
      # ...
    end
  end
end
```

For `:my_base_app`, we use an `only` instruction to exclude all files in
`lib/my_base_app` and `test/my_base_app` except for `application.ex` and
`repo.ex`.

```elixir
lib :my_base_app do
  only [
    "lib/my_base_app/application.ex",
    "lib/my_base_app/repo.ex"
  ]

  file Path.wildcard("priv/repo/**/*.exs", match_dot: true)
end
```

You may have a setup that requires you to add more files, such as `mailer.ex`.

Note that we also include all of the Repo's migrations and seeds scripts with
`file Path.wildcard(...)`. The `match_dot: true` ensures
`priv/repo/.formatter.exs` is ejected so that the ejected codebase is formatted
properly.

For `:my_base_app_web`, we also use an `only` instruction to only include
relevant files.

```elixir
lib :my_base_app_web do
  only [
    "lib/my_base_app_web/endpoint.ex",
    "lib/my_base_app_web/gettext.ex",
    "lib/my_base_app_web/router.ex",
    "lib/my_base_app_web/telemetry.ex",
    "lib/my_base_app_web/channels/user_socket.ex",
    "lib/my_base_app_web/templates/layout/app.html.heex",
    "lib/my_base_app_web/templates/layout/live.html.heex"
    "lib/my_base_app_web/templates/layout/root.html.heex",
    "lib/my_base_app_web/views/error_helpers.ex",
    "lib/my_base_app_web/views/error_view.ex",
    "lib/my_base_app_web/views/layout_view.ex"
  ]
end
```

> #### Base Web as an internal space {: .tip}
>
> We suggest utilizing the base web app (`my_base_app_web` in this case) as a
> place to create web pages that serve your team internally. (Using `only` to
> ensure they aren't ejected.) For example, creating pages that catalog and
> document all of your [Ejectable Apps](how-it-works.html#what-is-an-ejectable-app).
