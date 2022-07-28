# Code Transformations

Whenever `mix eject` is ran, a standard set of code transformations is applied
to the file contents of each file copied, except for those specified with `cp`
and `cp_r`.

## mix.exs Dependency Removal

Any Mix Dependency that is not directly or indirectly required by the app via
`mix.exs` or the `Plan` module is removed from the ejected `mix.exs`.

## Replacing the Base Project Name

The base project name, appearing anywhere in a file, is replaced by the ejected
app name. This applies to the following formats: `base_app`, `base-app`, and
`BaseApp`.

The base project name is the `:app` key returned by `project` in the `mix.exs`
file of the Base Project.

For example, the base project name in this `mix.exs` would be `:my_base_app`:

```elixir
def project do
  [
    app: :my_base_app,
    ...
  ]
end
```

Given the above `mix.exs`, if you were to run `mix eject MyEjectableApp`:

- `my_base_app` would be replaced with `my_ejectable_app`
- `my-base-app` would be replaced with `my-ejectable-app`
- `MyBaseApp` would be replaced with `MyEjectableApp`

## Code Fences

In any file, you can wrap "code fence" comments in order to only include the
code in an ejected app in certain scenarios.

To only include code if an an app depends on a Lib Dependency called `my_lib`,
wrap it in these comments:

```elixir
# <eject:lib:my_lib>
# ... code
# </eject:lib:my_lib>
```

To only include code if an an app depends on a Mix Dependency called
`absinthe`, wrap it in these comments:

```elixir
# <eject:mix:absinthe>
# ... code
# </eject:mix:absinthe>
```

To only include code if the ejected app is called `MyApp`, wrap it in these
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

## Modifiers from the Ejection Plan

Users can also specify arbitrary modifications that should be applied to
various files using the `modify` macro in the `Plan` module:

```elixir
modify ~r/.+_worker.ex/, file, app do
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

modify "lib/my_app_web/router.ex", file do
  # This modify block is like the one above, but the transformation will only
  # be ran for `lib/my_app_web/router.ex`.
end
```
