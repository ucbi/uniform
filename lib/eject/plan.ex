defmodule Eject.Plan.BeforeCompile do
  @moduledoc false
  defmacro __before_compile__(_env) do
    quote do
      def __modifiers__, do: @modifiers
    end
  end
end

defmodule Eject.Plan do
  @moduledoc ~S"""
  Defines the ejection plan for your project.

  When used, the plan expects the `:templates` option. For example, the plan:

      defmodule Plan do
        use Eject.Plan, templates: "priv/eject-templates"
      end

  Would search for templates in the `priv/eject-templates` directory. See
  `template/2` for more information.

  ## `eject` Block

  At minimum, the plan requires an `eject` block:

      defmodule Plan do
        use Eject.Plan, templates: "..."

        eject(app) do
          file "my_main_app/application.ex"
          cp_r "assets"
          # ...
        end
      end

  The `eject` block specifies files that should be ejected which aren't in the
  `lib/` directory of the app being ejected.

  See `eject/2` for more information.

  ## Files that are always ejected

  There are a handful of files that are automatically ejected. You do not need
  to specify these in the `eject` block.

  ```bash
  mix.exs
  mix.lock
  .gitignore
  .formatter.exs
  test/test_helper.exs
  ```

  ## `deps` Block

  Besides the `eject` block, the plan can also contain a `deps` block to
  configure dependencies.

      defmodule Plan do
        use Eject.Plan, templates: "..."

        deps do
          always do
            mix :phoenix
            lib :my_component_library
          end

          mix :absinthe do
            mix_deps [:absinthe_plug, :dataloader]
          end
        end
      end

  See `deps/1` for more information.

  ## `modify` Blocks

  Lastly, `modify` blocks can be used whenever you want to transform
  file contents during ejection. You can specify a specific filepath
  or use a regex to match multiple files.

      defmodule Plan do
        use Eject.Plan, templates: "..."

        modify "assets/js/app.js", file, app do
          String.replace(file, "SOME_VALUE_PER_APP", app.extra[:some_value])
        end

        modify ~r/_worker.ex/, file, app do
          # ...
        end
      end

  See `modify/4` for more information.

  ## Full Example

  Below is an example `Plan` module that shows off a majority of the features that can be used.

      defmodule MyApp.Eject.Plan do
        use Eject.Plan, templates: "lib/eject/templates"

        @impl Eject.Plan
        def extra(app) do
          theme =
            case app.name.underscore do
              "empire_" <> _ -> :empire
              "rebel_" <> _ -> :rebel
            end

          # set `app.extra[:theme]`
          [theme: theme]
        end

        @impl Eject.Plan
        def target_path(path, app) do
          if is_web_file?(path) do
            # modify the path to put it in `lib/some_app_web`
            String.replace(path, "lib/#{app.name.underscore}/", "lib/#{app.name.underscore}_web/")
          else
            path
          end
        end

        # files to eject in every app, which are outside `lib/that_app`
        eject(app) do
          # do not delete this root file when clearing the destination
          preserve ".env"

          # copy these directories wholesale; do NOT run them through code modifiers
          cp_r "assets"

          # eject these files which aren't in lib/the_app_directory
          file ".credo.exs"
          file ".github/workflows/elixir.yml"
          file "priv/static/#{app.extra[:theme]}-favicon.ico"
          file "lib/my_app_web.ex"

          # eject a file from an EEx template at "lib/eject/templates/config/runtime.exs.eex"
          # configure the templates directory on line 2
          template "config/runtime.exs"

          # conditionally eject some files
          if deploys_to_aws?(app) do
            file "file/required/by/aws"
            template "dynamic/file/required/by/aws"
          end

          if depends_on?(app, :lib, :some_lib) do
            template "dynamic/file/required/by/some_lib"
          end
        end

        # run the file contents through this modifier if the file is ejected
        modify "lib/my_app_web/templates/layout/root.html.heex", file, app do
          file
          |> String.replace("empire-favicon.ico", "#{app.extra[:theme]}-favicon.ico")
          |> String.replace("empire-apple-touch-icon.png", "#{app.extra[:theme]}-apple-touch-icon.png")
        end

        # configure dependencies from mix.exs and `lib/`
        deps do
          # always eject the dependencies in the `always do` block;
          # don't require adding them to eject.exs
          always do
            lib :my_app do
              # only eject the following files in `lib/my_app`
              only ["lib/my_app/application.ex"]
            end

            lib :my_app_web do
              # only eject the following files in `lib/my_app_web`
              only [
                "lib/my_app_web/endpoint.ex",
                "lib/my_app_web/router.ex",
                "lib/my_app_web/channels/user_socket.ex",
                "lib/my_app_web/views/error_view.ex",
                "lib/my_app_web/templates/layout/root.html.heex",
                "lib/my_app_web/templates/layout/app.html.heex",
                "lib/my_app_web/templates/layout/live.html.heex"
              ]
            end

            # always include these mix dependencies
            mix :credo
            mix :ex_doc
            mix :phoenix
            mix :phoenix_html
          end

          # if absinthe is included, also include absinthe_plug and dataloader
          mix :absinthe do
            mix_deps [:absinthe_plug, :dataloader]
          end

          lib :my_data_lib do
            # if my_data_lib is included, also include other_lib, faker, and norm
            lib_deps [:other_lib]
            mix_deps [:faker, :norm]

            # if my_data_lib is included, also eject these files
            file Path.wildcard("priv/my_data_repo/**/*.exs", match_dot: true)
            file Path.wildcard("test/support/fixtures/my_data_lib/**/*.ex")
          end
        end
      end

  """

  @doc """
  A hook to add more data to `app.extra`, beyond what's in the [Eject Manifest
  file](./Eject.html#module-the-eject-manifest-eject-exs).

  ### Example

  You may want to set the theme based on the name of the ejectable app.  In
  this case, add an 'extra' entry called 'theme', which will then be available
  through the app struct:

      def extra(app) do
        theme =
          case app.name.underscore do
            "work_" <> _ -> :work
            "personal_" <> _ -> :personal
            _ -> raise "App name must start with Work or Personal to derive theme."
          end

        [theme: theme]
      end

  """
  @callback extra(app :: Eject.App.t()) :: keyword

  @doc ~S"""
  Use this callback to modify the path of ejected files. It will be called for
  every file in a lib directory, along with every file specified via `file`, `template`,
  `cp`, and `cp_r`.

  If you don't want to modify the `path`, just return it.

  If not defined, the default implementation is:

      def target_path(path, _app), do: path

  ### Example

  You may want to place certain files in `lib/ejected_app_web` instead of `lib/ejected_app`.
  Let's say you have an `is_web_file?` function that identifies whether the file belongs in
  the `_web` directory. `target_path` might be something like this:

      def target_path(path, app) do
        if is_web_file?(path) do
          # modify the path to put it in `lib/some_app_web`
          String.replace(path, "lib/#{app.name.underscore}/", "lib/#{app.name.underscore}_web/")
        else
          path
        end
      end

  """
  @callback target_path(path :: Path.t(), app :: Eject.App.t()) :: Path.t()

  @optional_callbacks extra: 1, target_path: 2

  @doc """
       A macro for defining an ejection plan.

       The required `templates` path points to the EEx templates used by `Eject`.

       ### Examples

           defmodule MyBaseApp.Eject.Project do
             use Eject.Plan, templates: "lib/my_base_app/eject/templates"

       """ && false
  defmacro __using__(opts) do
    templates = opts[:templates]

    quote do
      @behaviour Eject.Plan
      @before_compile Eject.Plan.BeforeCompile
      import Eject.Plan, only: [modify: 4, modify: 3, deps: 1, eject: 2]
      import Eject.App, only: [depends_on?: 3]

      def __template_dir__, do: unquote(templates)

      def target_path(path, _app), do: path
      defoverridable target_path: 2

      Module.register_attribute(__MODULE__, :lib_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :mix_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :modifiers, accumulate: true)
    end
  end

  #
  # Modifying the contents of a file
  #

  @doc """
  Specify a file or regex pattern and a transformation function to apply to all
  files matching that pattern.

  ### Examples

      modify ~r/.+_worker.ex/, file, app do
        # Return modified `file` string
        # Only ran on files matching the regex
      end

      modify "lib/my_app_web/router.ex", file do
        # Return modified `file` string
        # Only ran on files with the exact path "lib/my_app_web/router.ex"
      end

  > #### "Magic" Variable Names {: .info}
  >
  > In the above examples, `file` and `app` work as function parameters,
  > which are available to the "function body" in between `do` and `end`.
  > The macro turns them into variables under the hood. As such, they can
  > be given different names.
  >
  > **Note that the final parameter (`app`) is optional, and can be excluded
  > if the `modify` function does not need it.**

  """
  @spec modify(
          pattern :: Path.t() | Regex.t(),
          file :: String.t(),
          app :: Eject.App.t(),
          block :: term
        ) :: term
  defmacro modify(path_or_regex, file, app, do: block) do
    line = __CALLER__.line
    fn_name = String.to_atom("modify_#{line}")

    quote do
      Eject.Plan.__register_modifier__(__MODULE__, unquote(path_or_regex), unquote(fn_name))
      def unquote(fn_name)(unquote(file), unquote(app)), do: unquote(block)
    end
  end

  @doc false
  defmacro modify(path_or_regex, file, do: block) do
    app = quote generated: true, do: var!(app)
    line = __CALLER__.line
    fn_name = String.to_atom("modify_#{line}")

    quote do
      Eject.Plan.__register_modifier__(__MODULE__, unquote(path_or_regex), unquote(fn_name))
      def unquote(fn_name)(unquote(file), unquote(app)), do: unquote(block)
    end
  end

  def __register_modifier__(mod, path_or_regex, fn_name) do
    Module.put_attribute(mod, :modifiers, {path_or_regex, {mod, fn_name}})
  end

  #
  # Configuring which files to eject outside of the files in the app's `lib` directory.
  #

  @doc """
  The `eject` block "receives" an `app` (see `Eject.App.t`) like a function.

  It is where you specify files which aren't in an included `lib/` directory
  that should be ejected.

  ## Files Tied to Lib Dependencies

  If a file or template should only be ejected in the case that a certain Lib
  Dependency is included, we recommend placing that in `lib/2` inside the
  `deps/1` block instead of in the `eject` block.

      # ❌ Don't do this
      eject(app) do
        if depends_on?(app, :lib, :my_lib) do
          file "some_file"
        end
      end

      # ✅ Instead, do this
      deps do
        lib :my_lib do
          file "some_file"
        end
      end

  """
  defmacro eject(app, do: block) do
    {:__block__, [], items} = block

    items =
      Enum.map(items, fn
        {:if, meta, [condition, [do: {:__block__, [], items}]]} ->
          {:if, meta, [condition, [do: items]]}

        item ->
          item
      end)

    quote do
      try do
        import Eject.Plan, except: [eject: 1, only: 1]

        def __eject__(unquote(app)),
          do: unquote(items) |> List.flatten() |> Enum.reject(&is_nil/1)
      after
        :ok
      end
    end
  end

  #
  # Dependencies
  #

  @doc """
  Eject automatically catalogs all Mix deps by looking into `mix.exs` to discover all Mix deps.
  It also catalogs all Lib deps by scanning the `lib/` directory.

  If you need to configure anything about a Mix or Lib dep, such as other dependencies
  that must be bundled along with it, use the `deps` block.

  See `mix/2`, `lib/2`, and `always/1` for more details.

  ### Example

      deps do
        always do
          lib :my_app do
            only ["lib/my_app/application.ex"]
          end

          mix :phoenix
        end

        mix :absinthe do
          mix_deps [:absinthe_plug, :dataloader]
        end

        lib :my_custom_aws_lib do
          lib_deps [:my_utilities_lib]
          mix_deps [:ex_aws, :ex_aws_ec2]
        end
      end

  """
  @spec deps(block :: term) :: term
  defmacro deps(_block = [do: block]) do
    prelude =
      quote do
        try do
          import Eject.Plan, only: [lib: 1, lib: 2, mix: 1, mix: 2, always: 1]
          @deps_always_block false
          unquote(block)
        after
          :ok
        end
      end

    postlude =
      quote unquote: false do
        lib_deps = @lib_deps |> Enum.reverse()
        mix_deps = @mix_deps |> Enum.reverse()

        def __deps__(:lib), do: unquote(Macro.escape(lib_deps))
        def __deps__(:mix), do: unquote(Macro.escape(mix_deps))
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  @doc """
  Inside of a `deps do` block, any Mix or Lib dependencies that should be
  included in every ejected app should be wrapped in an `always do` block:

      deps do
        always do
          # always eject the contents of `lib/some_lib`
          lib :some_lib

          # always eject the some_mix Mix dependency
          mix :some_mix
        end
      end

  """
  defmacro always(do: block) do
    quote do
      try do
        @deps_always_block true
        unquote(block)
      after
        @deps_always_block false
      end
    end
  end

  @doc """
  Eject considers all directories in the project root's `lib/` directory
  to be "lib dependencies".

  Since Eject is aware of all lib dependencies in `lib/`, you don't need to
  tell it about them.

  However, there are a few scenarios where you do need to list them in your `Plan` module:

  1. Specifying which lib dependencies should _always_ be ejected. (See
  `Eject.Plan.always/1`.)
  2. To specify that a lib dependency has other mix or lib dependencies. (I.e.
  Other mix packages or lib directories should always be ejected along with
  it.)
  3. To specify to eject other files that aren't in a `lib/` directory
  alongside a lib dependency.

  > #### Including Lib Dependencies in an App {: .info}
  >
  > To eject a lib dependency with a specific app (but not all), make sure to
  > put it in the app's
  > [Eject Manifest file](./Eject.html#module-the-eject-manifest-eject-exs),
  > or make it a `lib_dependency` of another dependency in the Manifest.

  ### Examples

      deps do
        always do
          # every app will have lib/utilities
          lib :utilities

          # every app will have lib/mix, but only my_app.some_task.ex will be ejected
          lib :mix do
            only ["lib/mix/tasks/my_app.some_task.ex"]
          end
        end

        # If eject.exs says to include sso_auth, then `lib/sso_auth` will be copied
        # along with `lib/other_utilities`. However, `some_file.ex` will never be
        # included. Also, the tesla mix dep will be included.
        lib :sso_auth do
          mix_deps [:tesla]
          lib_deps [:other_utilities]
          except ["lib/sso_auth/some_file.ex"]
        end

        mix :oban do
          # any app that is ejected with oban will also have oban_pro and oban_web
          mix_deps [:oban_pro, :oban_web]
        end
      end

  """
  defmacro lib(name, do: block) do
    opts =
      case block do
        {:__block__, _meta, opts} -> opts
        opt -> [opt]
      end

    quote do
      try do
        import Eject.Plan
        Eject.Plan.__lib__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  @doc false
  defmacro lib(name) do
    quote do
      Eject.Plan.__lib__(__MODULE__, unquote(name), [], @deps_always_block)
    end
  end

  @doc false
  def __lib__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
    lib_dep =
      Eject.LibDep.new!(%{
        name: name,
        lib_deps: opts |> Keyword.get(:lib_deps, []) |> List.wrap(),
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap(),
        always: always,
        file_rules: opts |> rule_opts() |> Eject.Rules.new()
      })

    Module.put_attribute(mod, :lib_deps, lib_dep)
  end

  @doc """
  Since Eject is aware of all mix dependencies in `mix.exs`, you don't need to
  tell it about them.

  However, there are two scenarios where you do need to list out mix dependencies:

  1. Specifying which mix dependencies should _always_ be ejected. (See
  `Eject.Plan.always/1`.)
  2. Whenever a mix dependency has other mix dependencies. (I.e. Other mix
  packages should always be ejected with it.)

  > #### Including Mix Dependencies in an App {: .info}
  >
  > To eject a mix dependency with a specific app (but not all), make sure to
  > include it as a dependency of lib dependencies (see `lib/2`) or put it in the
  > app's [Eject Manifest
  > file](./Eject.html#module-the-eject-manifest-eject-exs).

  ### Examples

      deps do
        always do
          # every app will have credo and ex_doc
          mix :credo
          mix :ex_doc
        end

        mix :oban do
          # any app that is ejected with oban will also have oban_pro and oban_web
          mix_deps [:oban_pro, :oban_web]
        end
      end

  """
  defmacro mix(name, do: block) do
    opts =
      case block do
        {:__block__, _meta, opts} -> opts
        opt -> [opt]
      end

    quote do
      try do
        import Eject.Plan, only: [mix_deps: 1]
        Eject.Plan.__mix__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  @doc false
  defmacro mix(name) do
    quote do
      Eject.Plan.__mix__(__MODULE__, unquote(name), [], @deps_always_block)
    end
  end

  @doc false
  def __mix__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
    mix_dep =
      Eject.MixDep.new!(%{
        name: name,
        always: always,
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap()
      })

    Module.put_attribute(mod, :mix_deps, mix_dep)
  end

  @doc false
  defmacro mix_deps(deps), do: {:mix_deps, List.wrap(deps)}

  @doc false
  defmacro lib_deps(deps), do: {:lib_deps, List.wrap(deps)}

  defp rule_opts(opts) do
    associated_files =
      Enum.flat_map(opts, fn opt ->
        case opt do
          {type, path_or_paths} when type in [:text, :template, :cp, :cp_r] ->
            path_or_paths
            |> List.wrap()
            |> Enum.map(&{type, &1})

          _ ->
            []
        end
      end)

    Keyword.put(opts, :associated_files, associated_files)
  end

  @doc """
  In `eject` and `lib` blocks, `file` is used to specify **files that are not
  in a `lib/` directory** which should be ejected in the app or along with the
  lib.

  ### Examples

      eject(app) do
        # every ejected app will include app.js
        file "assets/js/app.js"
      end

      deps do
        lib :aws do
          # for every app that includes the aws lib dependency,
          # some_aws_fixture.xml will also be included
          file "test/support/fixtures/some_aws_fixture.xml"
        end
      end
  """
  def file(path, opts \\ []), do: {:text, {path, opts}}

  @doc """
  In `eject` and `lib` blocks, `template` is used to specify EEx templates that
  should be rendered and then ejected.

  ### Template Directory and Destination Path

  Eject templates use a "convention over configuration" model
  that works like this:

  1. At the top of your `Plan` module, you specify a template directory
  like this:

      `use Eject, templates: "lib/eject/templates"`

  2. Templates must be placed in this directory at the relative path
  that they should be placed in, in the ejected directory.
  3. Templates must have the destination filename, appended with `.eex`.

  See the code snippet below for an example.

  ### Examples

      use Eject, templates: "priv/eject-templates"

      eject(app) do
        # priv/eject-templates/config/runtime.exs.eex will be rendered, and the
        # result will be placed in `config/runtime.exs` in every ejected app
        template "config/runtime.exs"
      end

      deps do
        lib :datadog do
          # for every app that includes `lib/datadog`,
          # priv/eject-templates/datadog/prerun.sh.eex will be rendered, and
          # the result will be placed in `datadog/prerun.sh`
          template "datadog/prerun.sh"
        end
      end

  """
  def template(path, opts \\ []), do: {:template, {path, opts}}

  @doc """
  `cp_r` works like `cp/2`, but for directory instead of a file.
  The directory is copied as-is with `File.cp_r!/3`.

  **None of the files are ran through Code Modifiers.**

  This is useful for directories that do not require modification,
  and contain many files.

  For example, the `assets/node_modules` directory in a Phoenix application
  would take ages to copy with `file Path.wildcard("assets/node_modules/**/*")`.
  Instead, use `cp_r "assets/node_modules"`.

  ### Examples

      eject(app) do
        cp_r "assets"
      end

      deps do
        lib :some_lib do
          cp_r "priv/files_for_some_lib"
        end
      end

  """
  def cp_r(path, opts \\ []), do: {:cp_r, {path, opts}}

  @doc """
  `cp` works exactly like `file/2`, except that **no transformations
  are applied to the file**.

  The file is copied as-is with `File.cp!/3`.

  ### Examples

      eject(app) do
        # every ejected app will have bin/some-binary, with the ACL mode changed to 555
        cp "bin/some-binary", chmod: 0o555
      end

      deps do
        lib :pdf do
          # apps that include the pdf lib will also have bin/convert
          cp "bin/convert"
        end
      end
  """
  def cp(path, opts \\ []), do: {:cp, {path, opts}}

  @doc """
  Whenever running `mix eject`, the contents in the destination directory will
  be deleted except for the `.git`, `deps`, and `_build` directories.

  If there are any other files or directories that you would like to
  **preserve** (by not deleting them), specify them with `preserve`:

      eject(app) do
        # .env will not be deleted immediately before ejection
        preserve ".env"
      end
  """
  def preserve(path), do: {:preserve, path}

  # Specifying allow/deny-lists that drive which files to include in a lib directory
  @doc false
  def except(paths), do: {:except, List.wrap(paths)}
  @doc false
  def only(paths), do: {:only, List.wrap(paths)}
end
