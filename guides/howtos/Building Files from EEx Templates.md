# Building files from EEx templates

EEx templates can be used to create files in Ejected Apps that don't exist in
the Base Project.

## An Example Scenario

Imagine you do not use [runtime
configuration](https://hexdocs.pm/elixir/main/Config.html#module-config-runtime-exs)
in your Base Project, but you want a `config/runtime.exs` in your ejected applications.

Furthermore, imagine the contents of `runtime.exs` need to be wildly different
between apps based on the Lib and Mix Dependencies of the app.

This is an ideal scenario for using an [EEx](https://hexdocs.pm/eex/EEx.html)
template. Below are the steps to create `runtime.exs` with an EEx template.

## Step 1: Set the template directory in your Blueprint module

```
defmodule MyApp.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "lib/uniform/templates"
```

## Step 2: Add the EEx file in the correct relative path

EEx templates must be added in the destination path, **relative to the templates
directory**.

So to emit our file into `config/runtime.exs`, we must create it in

```bash
lib/uniform/templates/config/runtime.exs.eex
\___________________/ \________________/\__/
        |                   |           |
templates directory     destination    .eex suffix
```

The path "prefix", `lib/uniform/templates`, must match the `templates` directory
specified with `use Uniform.Blueprint` above.

> #### Don't forget the .eex suffix {: .tip}
>
> Note above that the filename is the exact file name you want to emit,
> appended with `.eex`.

## Step 3: Write the template

Here is an example of what the `runtime.exs.eex` template might contain.

Note the use of [Code Fences](code-transformations.html#code-fences) at the end
of the file.

```elixir
import Config

<%= if MyApp.Uniform.Blueprint.deploys_to_fly_io?(app) do %>
  config :my_base_app, some_api_token: System.get_env("SOME_API_TOKEN")
<% end %>

config :my_base_app, MyBaseAppWeb.Endpoint,
  url: [
    host: System.get_env("HOST"),
    port: String.to_integer(System.get_env("EXTERNAL_PORT"))
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :my_base_app, MyBaseApp.Repo,
  priv: "priv/my_base_app_repo",
  url: System.get_env("DATABASE_URL")

# uniform:app:some_app
config :my_base_app, some_configuration: "just for some_app"
# /uniform:app:some_app
```

> #### The App struct in templates {: .tip}
>
> In EEx templates, the `Uniform.App` struct will be available as `app`. You can
> use the contents of `app.extra` to make decisions about what to render in the
> template.
>
> Also, the `Uniform.App.depends_on?/3` utility is available as `depends_on?` and
> can be used like this: `depends_on?.(app, :mix, :absinthe)`

> #### Code Transformations and templates {: .info}
>
> [Code Transformations](code-transformations.html) are ran **after** the
> template is generated. This means that you can inject the base app name into
> a template anywhere you want the ejected app name to appear, and it will be
> transformed into the ejected app name.
>
> So in the example above, instead of writing `config :<%= app.name.underscore %>`,
> we just wrote, `config :my_base_app`.
