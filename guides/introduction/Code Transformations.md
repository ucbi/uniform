# Code Transformations

During `mix uniform.eject`, there are 4 code transformations applied to file
contents. These transformations happen to every file except those ejected with
`cp` and `cp_r`.

They occur **in this order**.

1. [Unused mix.exs Dependencies are Removed](#mix-exs-dependency-removal)
2. [Blueprint Modifiers](#modifiers-from-the-ejection-blueprint) are ran
3. [The Base Project Name is replaced](#replacing-the-base-project-name) with the ejected app's name
4. [Code Fences](#code-fences) are processed

## mix.exs Dependency Removal

Any Mix Dependency that is not directly or indirectly required by the app via
`mix.exs` or the `Blueprint` module is removed from the ejected `mix.exs`.

## Modifiers from the Ejection Blueprint

Users can specify arbitrary modifications that should be applied to various
files using the `modify` macro in the [Blueprint](`Uniform.Blueprint`) module:

```elixir
modify ~r/.+_worker.ex/, fn file, app ->
  # `file` is a string containing the full file contents.
  # `app` is the `Uniform.App` struct. (The app being ejected.)
  # The string this function returns will be the ejected file contents.
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

Given the above `mix.exs`, if you were to run `mix uniform.eject my_ejectable_app`:

- `my_base_app` would be replaced with `my_ejectable_app`
- `my-base-app` would be replaced with `my-ejectable-app`
- `MyBaseApp` would be replaced with `MyEjectableApp`

> #### Replacement in file paths {: .info}
>
> This same replacement of `base_project_name` to `ejected_app_name` also
> occurs in file paths, but only with `this_format`. (Not `this-format` or
> `ThisFormat`.)
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

In any `.ex` or `.exs` file, you can use "code fence" comments to remove code
unless certain criteria are met.

To remove code unless the ejected app depends on a Lib Dependency called
`my_lib`, wrap it in these comments:

```elixir
# uniform:lib:my_lib
# ... code
# /uniform:lib:my_lib
```

To remove code unless the ejected app depends on a Mix Dependency called
`absinthe`, wrap it in these comments:

```elixir
# uniform:mix:absinthe
# ... code
# /uniform:mix:absinthe
```

To remove code unless the ejected app is called `MyApp`, wrap it in these
comments:

```elixir
# uniform:app:my_app
# ... code
# /uniform:app:my_app
```

Finally, to **always** remove a chunk of code whenever ejection happens, wrap
it in these comments:

```elixir
# uniform:remove
# ... code
# /uniform:remove
```

> #### Code Fence comments are removed on ejection {: .info}
>
> Note that regardless of whether `mix uniform.eject` keeps or deletes the code in a
> code fence, the code fence comments themselves (like `# uniform:app:my_app`)
> are always removed.
>
> Furthermore, `mix uniform.eject` runs `mix format` on the ejected codebase at
> the end. So you always end up with "clean" looking code.

### Code Fences for other languages

Code Fences are also processed for `.js`/`.ts`/`.jsx`/`.tsx` files using JS
single-line comments.

```js
// uniform:lib:my_lib
// ...
// /uniform:lib:my_lib
```

If you would like to support Code Fences for other languages or file types, you
can do so using `Uniform.Blueprint.modify/2` and
`Uniform.Modifiers.code_fences/3`.

```elixir
# code fences for SQL files
modify ~r/\.sql$/, fn file, app ->
  code_fences(file, app, "--")
end

# code fences for Rust files
modify ~r/\.rs$/, &code_fences(&1, &2, "//")
```

## Disabling Code Transformations for a file

If you have a file that should not have Code Transformations applied upon
ejection, use [`cp`](Uniform.Blueprint.html#cp/2) instead of
[`file`](Uniform.Blueprint.html#file/2).

If there is an entire directory of contents that should not be modified, use
[`cp_r`](Uniform.Blueprint.html#cp_r/2), which will be much faster.

