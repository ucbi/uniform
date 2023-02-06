# Changelog

## v0.6.0 (2023-02-06)

  * Adds support for suffix on eject fences (#46)

## v0.5.3 (2022-09-07)

  * Fix to ensure Blueprint is recompiled when templates change (#45)

## v0.5.2 (2022-09-02)

  * Include Blueprint template file in published Hex package (#43)

## v0.5.1 (2022-08-19)

  * Fix issue where template files beginning with `.` weren't compiled (#40)
  * Remove warning whenever `app` not used by a template (#40)

## v0.5.0 (2022-08-19)

  * Support globs with `Path.wildcard` wildcard characters in `file` (#37)
  * Remove support for lists of paths in `file`, `template`, `cp`, and `cp_r` (#37)

## v0.4.0 (2022-08-15)

  * Rename `code_fences` to `eject_fences`
  * Compile templates into Blueprint (#36)

## v0.3.0 (2022-08-09)

  * Make `templates` optional in `use Uniform.Blueprint` (#33)
  * Stop requiring `# uniform:deps` code fences in mix.exs (#34)

## v0.2.0 (2022-08-08)

  * Change API of `mix uniform.eject` to accept `my_app` instead of `MyApp` (#31)
  * Add `mix uniform.ejectable_apps` (#31)
  * Add `Uniform.ejectable_app_names` and `Uniform.ejectable_apps` to public API (#31)
  * Automatically import `code_fences/3` in Blueprint (#30)

## v0.1.1 (2022-08-06)

  * Support captured anonymous functions with `modify/2` (#26)
