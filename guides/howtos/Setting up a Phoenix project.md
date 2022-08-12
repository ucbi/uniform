# Setting up a Phoenix project

> This guide walks through a typical process for setting up a Phoenix project.
> It assumes you've read the [How It Works](how-it-works.html) and [Getting
> Started](getting-started.html) guides.

Imagine creating an entire new application simply by adding a Route and a
single LiveView to an existing Elixir project.

This is in fact the vision that drove the creation of Uniform. The overhead of
experimenting with new apps becomes extremely low, incentivizing the team to
try out ideas without being inhibited by initial setup time.

## Setting up your Blueprint module

Below is an example [Blueprint](Uniform.Blueprint.html) module for ejecting the files
common to Phoenix applications.

```elixir
defmodule MyBaseApp.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "lib/my_base_app/uniform/templates"

  base_files do
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

## The `base_files` section

```elixir
base_files do
  cp_r "assets"
  cp_r "priv/static"

  file "lib/my_base_app_web.ex"
  file Path.wildcard("config/**/*.exs")
  file Path.wildcard("test/support/*_case.ex")
end
```

In the [base_files](Uniform.Blueprint.html#base_files/1) section, we specify
files that should _always_ be ejected in every app. Phoenix apps will typically
have CSS and JS assets in the `assets` directory. They'll also have static
files to be served as-is in `priv/static`. Some of these files are binary
(non-text) files, and we assume none of them need to pass through the [Code
Transformation](code-transformations.html) phase. That's why the first two
lines are included.

```elixir
cp_r "assets"
cp_r "priv/static"
```

Note that `cp_r` instructs `mix uniform.eject` to copy all the directory
contents (using `File.cp_r!/3`).

Phoenix apps typically have a `Web` module which is used to construct
Controllers, Views, Routers, and LiveViews. Since this file is typically in
`lib/` directly (and not in a sub-directory of `lib/`), we include it here in
the `base_files` section.

```elixir
file "lib/my_base_app_web.ex"
```

We also proceed with the assumption that the ejected app will need the Base
Project's configuration files.

```elixir
file Path.wildcard("config/**/*.exs")
```

## The `deps` section

In the `deps` section, we put both `lib :my_base_app` and `lib
:my_base_app_web` inside `always do` so that their contents are always ejected
without having to specify `lib_deps: [:my_base_app, :my_base_app_web]` in the
`uniform.exs` manifest of every app.

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

## The Phoenix Router

A simple way to set up your `Phoenix.Router` is to put the routes for all of
your apps in a single router. Then, use [Eject
Fences](code-transformations.html#eject-fences) and `Uniform.Blueprint.modify/2`
to transform the router upon ejection.

Let's look at an example. We'll explain each part below.

```elixir
defmodule MyBaseAppWeb.Router do
  use MyBaseAppWeb, :router

  pipeline :browser do
    # ...
  end

  # uniform:app:some_app
  scope "/some-app", SomeAppWeb do
    pipe_through :browser

    get "/widgets", WidgetController, :index
    get "/widgets/new", WidgetController, :new
    post "/widgets/new", WidgetController, :create
    get "/widgets/:widget_id", WidgetController, :show
  end
  # /uniform:app:some_app

  # uniform:app:another_app
  scope "/another-app", AnotherAppWeb do
    pipe_through :browser

    get "/posts", PostController, :index
    get "/posts/new", PostController, :new
    post "/posts/new", PostController, :create
    get "/posts/:post_id", PostController, :show
  end
  # /uniform:app:another_app
end
```

You'll want to structure the router for reuse by including any pipelines (e.g.
`:browser` or `:api`) that your apps will need.

```
pipeline :browser do
  # ...
end
```

Next, add scopes for each app, wrapped in [Eject
Fences](code-transformations.html#eject-fences). This ensures ejected routers
will only contain routes related to the ejected app.

```elixir
# uniform:app:some_app
scope "/some-app", SomeAppWeb do
  # ...
end
# /uniform:app:some_app
```

> You'll need to add controllers/views/etc inside of the app's `lib` directory.
>
> For example, `SomeAppWeb.WidgetController` should be in `lib/some_app`.
>
> (Probably at `lib/some_app/controllers/widget_controller.ex`.)

Prefix the paths of each scope with `/app-name` (like `/some-app` above) so
that each app has a predictable, separated URL structure when running the Base
Project locally.

As a last step, we need to remove the `/app-name` path prefix
during ejection. We can do this with `modify`.

```elixir
defmodule MyBaseApp.Uniform.Blueprint do
  use Uniform.Blueprint

  modify "lib/my_base_app_web/router.ex", fn file, app ->
    String.replace(
      file,
      "scope \"/#{app.name.hyphen}\"",
      "scope \"/\""
    )
  end
end
```

With this modifier, the following code

```elixir
scope "/some-app", SomeAppWeb do
```

Changes to

```elixir
scope "/", SomeAppWeb do
```

In the ejected codebase.

This method is a great starting point. Before you reach dozens of apps, you may
want to consider other methods that allow you to define routes in a separate
file per app.

### Internal Pages

We encourage running all apps simultaneously via the Base Project as your
development environment. In such a setup, it can be useful to add other pages
to the Base Project that aren't intended to be ejected with any app.

For example, you might add a page that catalogs and links to your various apps.
We recommend adding these routes and wrapping them all in `# uniform:remove`
Eject Fences as in the example above.

```elixir
# uniform:remove
scope "/", SomeAppWeb do
  pipe_through :browser

  get "/internal-team-page", InternalTeamController, :index
end
# /uniform:remove
```

## Eject Fences Everywhere!

There are other files which are central for running Elixir apps.

Similarly to the Phoenix Router, we recommend that you add the code required by
each of your apps and [Lib Dependencies](dependencies.html#lib-dependencies) to
all of these files. Then, use [Eject Fences](code-transformations.html#eject-fences)
to selectively remove code during ejection.

Let's examine what this might look like for `application.ex`, `mix.exs`, and
`config/*.exs` files.

### Application

Your `Application` file at `lib/my_base_app/application.ex` is a critical piece
of Elixir applications since it's used to start processes and supervisors at
the start of the application.

Here's what an example `Application` file would look like with Eject Fences
applied.

```elixir
defmodule MyBaseApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyBaseAppWeb.Endpoint,
      {Phoenix.PubSub, name: MyBaseApp.PubSub},
      MyBaseAppWeb.Presence,
      MyBaseAppWeb.Telemetry,

      # uniform:lib:my_first_data_lib
      MyFirstDataLib.Repo,
      # /uniform:lib:my_first_data_lib

      # uniform:lib:my_second_data_lib
      MySecondDataLib.Repo,
      MySecondDataLib.Vault,
      # /uniform:lib:my_second_data_lib

      # uniform:remove
      SomeDevelopmentOnlyDB.Repo,
      # /uniform:remove

      # uniform:mix:oban
      {Oban, ...},
      # /uniform:mix:oban
    ]

    # ...
  end
end
```

Notice that code which should always be ejected does not get surrounded by
Eject Fences.

### mix.exs

Some dependencies require modifying `mix.exs`. For example, the
[exq](https://hexdocs.pm/exq) Hex package says to add `:exq` to `application`
in `mix.exs`.

```elixir
def application do
  [
    applications: [:logger, :exq],
    # ...
  ]
end
```

But what if only some of your apps require exq? Wrap the exq-specific code in
Eject Fences, and it will only be included when exq is required.

```elixir
def application do
  [
    applications: [
      :logger,
      # uniform:mix:exq
      :exq
      # /uniform:mix:exq
    ],
    # ...
  ]
end
```

#### You don't need to use Eject Fences in `deps` {: .tip}

Note that removing deps from the `deps` section of `mix.exs` is automatic, so
this would not be required.

```elixir
# ❌ Do NOT wrap individual deps in eject fences
defp deps do
  [
    # uniform:mix:jason
    {:jason, "~> 1.0"}
    # /uniform:mix:jason
  ]
end
```

### Config Files

Many dependencies also require configuration. Apply Eject Fences in your
configuration files for the same result.

```elixir
# uniform:mix:guardian
config :my_base_app, MyBaseApp.Guardian,
       issuer: "my_base_app",
       secret_key: ...
# /uniform:mix:guardian
```
