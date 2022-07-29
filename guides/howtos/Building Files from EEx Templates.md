# Building Files from EEx Templates

EEx templates can be used to create files in ejected apps that don't exist in
the Base Project.

## An Example Scenario

Imagine you do not use [runtime
configuration](https://hexdocs.pm/elixir/main/Config.html#module-config-runtime-exs)
in your Base Project, but you might want a `config/runtime.exs` in your
ejected applications.

Furthermore, imagine the contents of `runtime.exs` need to be wildly different
between apps depending on the dependencies of the app.

This is an ideal scenario for using an [EEx](https://hexdocs.pm/eex/EEx.html)
template. Below are the steps to create the `runtime.exs` with an EEx template.

## Step 1: Set the template directory in your Plan module

```
defmodule MyApp.Eject.Plan do
  use Eject.Plan, templates: "lib/eject/templates"
```

## Step 2: Add the EEx file in the correct relative path

EEx templates are added in the ejected app in a path that mirrors its path in
the templates directory.

So to emit our file into `config/runtime.exs`, we must create it here because
of the templates directory we chose in Step 1.

```bash
lib/eject/templates/config/runtime.exs.eex
```

Note that the filename is the exact file name you want to emit, appended with
`.eex`.

## Step 3: Write the template

Here is an example of what the `runtime.exs` template might contain.

```elixir
import Config

<%= if MyApp.Eject.Plan.deploys_to_fly_io?(app) do %>
  config :my_base_app, some_api_token: System.get_env("SOME_API_TOKEN")
<% end %>

if config_env() not in [:dev, :test] do
  config :my_base_app, MyBaseAppWeb.Endpoint,
    url: [
      host: System.get_env("HOST"),
      port: String.to_integer(System.get_env("EXTERNAL_PORT"))
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  config :my_base_app, MyBaseApp.Repo,
    priv: "priv/my_base_app_repo",
    url: System.get_env("DATABASE_URL")
end

# <eject:app:some_app>
config :my_base_app, some_configuration: "just for some_app"
# </eject:app:some_app>
```

Note the use of [Code Fences](code-transformations.html#code-fences) at the end
of the file.

> #### The App struct in templates {: .tip}
>
> In EEx templates, the `Eject.App` struct will be available as `app`. You can
> inspect `app.extra` to make decisions about what to render in the template.
>
> Also, the `Eject.App.depends_on?/3` utility is available as `depends_on?` and
> can be used like this: `depends_on?.(app, :mix, :absinthe)`

> #### Code Transformations and Templates {: .info}
>
> [Code Transformations](code-transformations.html) are ran after the template
> is generated. This means that you can inject the base app name into a
> template anywhere you want the ejected app name to appear, instead of
> doing something like `<%= app.name.underscore %>`.
