# Code Transformations

During `mix eject`, there are 4 code transformations applied to file contents.
These transformations happen to every file, except those ejected with `cp` and `cp_r`.

They occur **in this order**.

1. [Unused mix.exs Dependencies are Removed](#mix-exs-dependency-removal)
2. [Plan Modifiers](#modifiers-from-the-ejection-plan) are ran
3. [The Base Project Name is replaced](#replacing-the-base-project-name) with the ejected app's name
4. [Code Fences](#code-fences) are processed

> #### Disabling Code Transformations for a file {: .tip}
>
> If you have a file that should not have Code Transformations applied upon
> ejection, use [`cp`](Eject.Plan.html#cp/2) instead of
> [`file`](Eject.Plan.html#file/2).
>
> If there is an entire directory of contents that should not be modified, use
> [`cp_r`](Eject.Plan.html#cp_r/2), which will be much faster.

## mix.exs Dependency Removal

Any Mix Dependency that is not directly or indirectly required by the app via
`mix.exs` or the `Plan` module is removed from the ejected `mix.exs`.

## Modifiers from the Ejection Plan

Users can specify arbitrary modifications that should be applied to various
files using the `modify` macro in the [Plan](`Eject.Plan`) module:

```elixir
modify ~r/.+_worker.ex/, fn file, app ->
  # This code will be ran for every file whose relative path in the base
  # project matches the regex.
  #
  # `file` is a string containing the full file contents.
  #
  # `app` is the `Eject.App` struct of the given app being ejected.
  #
  # This is essentially a function body, must return a string with
  # the modified file contents to eject.
end

modify "lib/my_app_web/router.ex", fn file ->
  # This modifier is like the one above, but the transformation will only
  # be ran for `lib/my_app_web/router.ex`.
end
```

## Replacing the Base Project Name

The base project name, appearing anywhere in a file, is replaced by the ejected
app name. This applies to the following formats: `base_app`, `base-app`, and
`BaseApp`.

The base project name is the `:app` key returned by `project` in the `mix.exs`
file of the Base Project. (For example, `:my_base_app` below.)

```elixir
# mix.exs
def project do
  [
    app: :my_base_app, # <- base project name
    ...
  ]
end
```

Given the above `mix.exs`, if you were to run `mix eject MyEjectableApp`:

- `my_base_app` would be replaced with `my_ejectable_app`
- `my-base-app` would be replaced with `my-ejectable-app`
- `MyBaseApp` would be replaced with `MyEjectableApp`

> #### Replacement in file paths {: .info}
>
> This same replacement of `base_project_name` to `ejected_app_name` also occurs
> in file paths, but only with `this_format`. (Not `this-format` or `ThisFormat`.)
>
> This means a file at `lib/base_project_name/foo.ex` would be ejected to
> `lib/ejected_app_name/foo.ex`.

This means that a file like this

```elixir
defmodule MyBaseAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_base_app

  socket "/socket", MyBaseAppWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug MyBaseAppWeb.Router
end
```

Would be transformed to this

```elixir
defmodule MyEjectableAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_ejectable_app

  socket "/socket", MyEjectableAppWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug MyEjectableAppWeb.Router
end
```

## Code Fences

In any file, you can use "code fence" comments to remove code unless certain
criteria are met.

To remove code unless the ejected app depends on a Lib Dependency called
`my_lib`, wrap it in these comments:

```elixir
# <eject:lib:my_lib>
# ... code
# </eject:lib:my_lib>
```

To remove code unless the ejected app depends on a Mix Dependency called
`absinthe`, wrap it in these comments:

```elixir
# <eject:mix:absinthe>
# ... code
# </eject:mix:absinthe>
```

To remove code unless the ejected app is called `MyApp`, wrap it in these
comments:

```elixir
# <eject:app:my_app>
# ... code
# </eject:app:my_app>
```

Finally, to **always** remove a chunk of code whenever ejection happens, wrap
it in these comments:

```elixir
# <eject:remove>
# ... code
# </eject:remove>
```

