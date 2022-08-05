defmodule Uniform.Blueprint.BeforeCompile do
  @moduledoc false
  defmacro __before_compile__(_env) do
    quote do
      def __modifiers__, do: @modifiers
      def __preserve__, do: @preserve
    end
  end
end

defmodule Uniform.Blueprint do
  @moduledoc ~S"""
  Defines the ejection blueprint for your project.

  When used, the blueprint expects the `:templates` option. For example, the
  blueprint:

      defmodule Blueprint do
        use Uniform.Blueprint, templates: "priv/uniform-templates"
      end

  Would search for templates in the `priv/uniform-templates` directory. See
  `template/2` for more information.

  ## The `base_files` Section

  The `base_files` section specifies files that should be ejected which aren't
  in `lib/my_app`. (When running `mix uniform.eject MyApp`.)

      defmodule Blueprint do
        use Uniform.Blueprint, templates: "..."

        base_files do
          file "my_main_app/application.ex"
          cp_r "assets"
          # ...
        end
      end

  See `base_files/1` for more information.

  ## Files that are always ejected

  There are a handful of files that are automatically ejected. You do not need
  to specify these in the `base_files` section.

  ```bash
  mix.exs
  mix.lock
  .gitignore
  .formatter.exs
  test/test_helper.exs
  ```

  ## The `deps` Section

  Besides the `base_files` section, the blueprint can also contain a `deps`
  section to configure dependencies.

      defmodule Blueprint do
        use Uniform.Blueprint, templates: "..."

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

  ## Modifying files programmatically with `modify`

  Lastly, `modify` can be used whenever you want to transform file contents
  during ejection. You can specify a specific filepath or use a regex to match
  multiple files.

      defmodule Blueprint do
        use Uniform.Blueprint, templates: "..."

        modify "assets/js/app.js", fn file, app ->
          String.replace(file, "SOME_VALUE_PER_APP", app.extra[:some_value])
        end

        modify ~r/_worker.ex/, &MyApp.Modify.modify_workers/1

  See `modify/2` for more information.

  ## Preserving files

  Whenever running `mix uniform.eject`, the contents in the destination
  directory will be deleted except for the `.git`, `deps`, and `_build`
  directories.

  If there are any other files or directories *in the project's root folder*
  that you would like to preserve (by not deleting them), specify them with
  `@preserve`.

      # .env will not be deleted immediately before ejection
      @preserve [
        ".env"
      ]

  ## Full Example

  Below is an example `Blueprint` module that shows off a majority of the
  features that can be used.

      defmodule MyApp.Uniform.Blueprint do
        use Uniform.Blueprint, templates: "lib/uniform/templates"

        # do not delete this root file when clearing the destination
        @preserve [".env"]

        @impl Uniform.Blueprint
        def extra(app) do
          theme =
            case app.name.underscore do
              "empire_" <> _ -> :empire
              "rebel_" <> _ -> :rebel
            end

          # set `app.extra[:theme]`
          [theme: theme]
        end

        @impl Uniform.Blueprint
        def target_path(path, app) do
          if is_web_file?(path) do
            # modify the path to put it in `lib/some_app_web`
            String.replace(path, "lib/#{app.name.underscore}/", "lib/#{app.name.underscore}_web/")
          else
            path
          end
        end

        # files to eject in every app, which are outside `lib/that_app`
        base_files do
          # copy these directories wholesale; do NOT run them through code modifiers
          cp_r "assets"

          # eject these files which aren't in lib/the_app_directory
          file ".credo.exs"
          file ".github/workflows/elixir.yml"
          file "priv/static/#{app.extra[:theme]}-favicon.ico"
          file "lib/my_app_web.ex"

          # eject a file from an EEx template at "lib/uniform/templates/config/runtime.exs.eex"
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
          # always eject the dependencies in the `always` section;
          # don't require adding them to uniform.exs
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
  A hook to add more data to `app.extra`, beyond what's in the [Uniform
  Manifest file](./getting-started.html#add-uniform-manifests).

  ## Example

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
  @callback extra(app :: Uniform.App.t()) :: keyword

  @doc ~S"""
  Use this callback to modify the path of ejected files. It will be called for
  every file in a lib directory, along with every file specified via `file`,
  `template`, `cp`, and `cp_r`.

  If you don't want to modify the `path`, just return it.

  If not defined, the default implementation is:

      def target_path(path, _app), do: path

  ## Example

  You may want to place certain files in `lib/ejected_app_web` instead of
  `lib/ejected_app`.  Let's say you have an `is_web_file?` function that
  identifies whether the file belongs in the `_web` directory. `target_path`
  might be something like this:

      def target_path(path, app) do
        if is_web_file?(path) do
          # modify the path to put it in `lib/some_app_web`
          String.replace(path, "lib/#{app.name.underscore}/", "lib/#{app.name.underscore}_web/")
        else
          path
        end
      end

  """
  @callback target_path(path :: Path.t(), app :: Uniform.App.t()) :: Path.t()

  @doc ~S"""
  This callback works like the `except/1` instruction for Lib Dependencies,
  except that it applies to the `lib` folder of the ejected app itself.

  When running `mix uniform.eject MyApp`, any files in `lib/my_app` or
  `test/my_app` which match the paths or regexes returned by `app_lib_except`
  will **not** be ejected.

      def app_lib_except(app) do
        ["lib/#{app.name.underscore}/hidden_file.ex"]
      end

  """
  @callback app_lib_except(app :: Uniform.App.t()) :: [Path.t() | Regex.t()]

  @optional_callbacks extra: 1, target_path: 2, app_lib_except: 1

  @doc """
       A macro for defining an ejection blueprint.

       The required `templates` path points to the EEx templates used by
       Uniform.

       ### Examples

           defmodule MyBaseApp.Uniform.Project do
             use Uniform.Blueprint, templates: "lib/my_base_app/uniform/templates"

       """ && false
  defmacro __using__(opts) do
    templates = opts[:templates]

    quote do
      @behaviour Uniform.Blueprint
      @before_compile Uniform.Blueprint.BeforeCompile

      # default value of @preserve
      @preserve []

      import Uniform.Blueprint, only: [modify: 2, deps: 1, base_files: 1]
      import Uniform.App, only: [depends_on?: 3]

      def __template_dir__, do: unquote(templates)

      Module.register_attribute(__MODULE__, :lib_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :mix_deps, accumulate: true)
      Module.register_attribute(__MODULE__, :modifiers, accumulate: true)
    end
  end

  #
  # Modifying the contents of a file
  #

  @doc """
  Specify a file path or regex pattern and a transformation function, which
  must return the new file contents as a string.

  The first argument of `modify` must be either the relative path of a file in
  your Base Project, or a regex which matches against those relative paths.

      # exact (relative) path
      modify "tests/path/to/specific_test.exs", fn file -> ... end

      # regex
      modify ~r/.+_test.exs/, fn file -> ... end

  The second argument of `modify` must either be a function capture

      modify ~r/.+_test.exs/, &MyApp.Modify.modify_tests/1
      modify ~r/.+_test.exs/, &MyApp.Modify.modify_tests/2

  Or an anonymous function

      modify ~r/.+_test.exs/, fn file ->
        # ...
      end

      modify ~r/.+_test.exs/, fn file, app ->
        # ...
      end

  If the function is 1-arity, it will receive the file contents. If it's
  2-arity, it will receive the file contents and the `Uniform.App` struct.

  ## Examples

      modify "config/config.exs", file do
        file <>
          ~S'''
          if config_env() in [:dev, :test] do
            import_config "#\{config_env()}.exs"
          end
          '''
      end

      modify ~r/.+_worker.ex/, fn file, app ->
        String.replace(file, "SOME_VALUE_PER_APP", app.extra[:some_value])
      end

  """
  @spec modify(
          pattern :: Path.t() | Regex.t(),
          fun ::
            (file :: String.t(), Uniform.App.t() -> String.t())
            | (file :: String.t() -> String.t())
        ) :: term
  defmacro modify(path_or_regex, {:fn, _, _} = fun) do
    # anonymous functions cannot be saved into module attributes, so create a
    # named function
    fn_name = String.to_atom("__modify_line_#{__CALLER__.line}__")

    quote do
      Uniform.Blueprint.validate_path_or_regex!(unquote(path_or_regex))

      Module.put_attribute(
        __MODULE__,
        :modifiers,
        {unquote(path_or_regex), Function.capture(__MODULE__, unquote(fn_name), 2)}
      )

      def unquote(fn_name)(file, app) do
        f = unquote(fun)

        case f do
          f when is_function(f, 1) -> f.(file)
          f when is_function(f, 2) -> f.(file, app)
        end
      end
    end
  end

  defmacro modify(path_or_regex, {:&, _, _} = fun) do
    quote do
      Uniform.Blueprint.validate_path_or_regex!(unquote(path_or_regex))
      Module.put_attribute(__MODULE__, :modifiers, {unquote(path_or_regex), unquote(fun)})
    end
  end

  @doc false
  def validate_path_or_regex!(path_or_regex) do
    case path_or_regex do
      path when is_binary(path) ->
        :ok

      %Regex{} ->
        :ok

      _ ->
        raise ArgumentError,
          message: """
          modify/2 expects a (string) path or a regex (~r/.../) as the first argument. Received #{inspect(path_or_regex)}
          """
    end
  end

  defmacro modify(path_or_regex, fun) do
    quote do
      raise ArgumentError,
        message: """
        modify/2 expects an anonymous function of a function capture as the 2nd argument.

        Received:

            #{inspect(unquote(fun))}

        Instead, either pass an anonymous function:

            modify #{inspect(unquote(path_or_regex))}, fn file ->
              # ...
            end

            modify #{inspect(unquote(path_or_regex))}, fn file, app ->
              # ...
            end

        Or pass a function capture:

            modify #{inspect(unquote(path_or_regex))}, &modify_tests/1
            modify #{inspect(unquote(path_or_regex))}, &Modifiers.modify_other_file/2

        """
    end
  end

  #
  # Configuring which files to eject outside of the files in the app's `lib` directory.
  #

  @doc ~S"""
  The `base_files` section is where you specify files outside of an ejected
  app's `lib/my_app` and `test/my_app` directories which should always be
  ejected.

  This section has access to an [`app`](`t:Uniform.App.t/0`) variable which can
  be used to build the instructions or conditionally include certain files with
  `if`.

      base_files do
        # interpolating the app name into a path dynamically
        cp "priv/static/images/#{app.name.underscore}_logo.png"

        # conditional instructions
        if deploys_to_fly_io?(app) do
          template "fly.toml"
        end
      end

  **Note that `if` conditionals cannot be nested here.**

  ## API Reference

  The following instructions can be given in the `base_files` section:

  - `file/2` ejects a single file or list of files
  - `template/2` creates a new file on ejection from an EEx template
  - `cp/1` copies a file (like `file/2`) without running it through [Code
    Transformations](code-transformations.html). This is useful for binary
    files such as images or executable.
  - `cp_r/1` copies an entire **directory** of files without [Code
    Transformations](code-transformations.html).

  ## Example

      base_files do
        file ".credo.exs"
        file Path.wildcard("config/**/*.exs")
        template "config/runtime.exs"
        cp "bin/some-executable"
        cp_r "assets"
        except ["lib/#{app.name.underscore}/hidden_file.ex"]
      end

  ## Files in `lib`

  Typically, the `base_files` section only contains files that aren't in `lib`,
  since files in `lib/app_being_ejected` and `lib/required_lib_dependency` are
  ejected automatically.

      # ❌ Don't do this
      base_files do
        file "lib/my_lib/some_file.ex"
      end

      # ✅ Instead, do this (lib/my_app/uniform.exs)
      [
        lib_deps: [:my_lib]
      ]

  ## Files outside `lib` but tied to Lib Dependencies

  If a file or template should only be ejected in the case that a certain Lib
  Dependency is included, we recommend placing that in `lib/2` inside the
  `deps/1` section instead of in `base_files`.

      # ❌ Don't do this
      base_files do
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
  defmacro base_files(do: block) do
    {:__block__, [], items} = block

    items =
      Enum.map(items, fn
        {:if, meta, [condition, [do: {:__block__, [], items}]]} ->
          {:if, meta, [condition, [do: items]]}

        item ->
          item
      end)

    # inject magic `app` variable
    app = quote generated: true, do: var!(app)

    quote do
      try do
        import Uniform.Blueprint, except: [base_files: 1, only: 1]

        def __base_files__(unquote(app)),
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
  Uniform automatically catalogs all Mix deps by looking into `mix.exs` to
  discover all Mix deps.  It also catalogs all Lib deps by scanning the `lib/`
  directory.

  If you need to configure anything about a Mix or Lib dep, such as other
  dependencies that must be bundled along with it, use the `deps` block.

  See `mix/2`, `lib/2`, and `always/1` for more details.

  ## Example

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
          import Uniform.Blueprint, only: [lib: 1, lib: 2, mix: 1, mix: 2, always: 1]
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
  Uniform considers all directories in the project root's `lib/` directory to
  be "lib dependencies".

  Since Uniform is aware of all lib dependencies in `lib/`, you don't need to
  tell it about them.

  However, there are a few scenarios where you do need to list them in your `Blueprint` module:

  1. Specifying which lib dependencies should _always_ be ejected. (See
     `Uniform.Blueprint.always/1`.)
  2. To specify that a lib dependency has other mix or lib dependencies. (I.e.
     Other mix packages or lib directories should always be ejected along with
     it.)
  3. To specify to eject other files that aren't in a `lib/` directory
     alongside a lib dependency.

  > #### Including Lib Dependencies in an App {: .info}
  >
  > To eject a lib dependency with a specific app (but not all), make sure to
  > put it in the app's [Uniform Manifest
  > file](./getting-started.html#add-uniform-manifests), or make it a
  > `lib_dependency` of another dependency in the Manifest.

  ## Examples

      deps do
        always do
          # every app will have lib/utilities
          lib :utilities

          # every app will have lib/mix, but only my_app.some_task.ex will be ejected
          lib :mix do
            only ["lib/mix/tasks/my_app.some_task.ex"]
          end
        end

        # If uniform.exs says to include sso_auth, then `lib/sso_auth` will be copied
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

  ## Associated Files

  Sometimes, when a Lib Dependency is ejected with an app, there are other
  files outside of `lib/that_library` which should also be ejected.

  In this scenario, you can use these instructions used in `base_files/1` to
  denote them.

  - `file/2`
  - `template/2`
  - `cp/1`
  - `cp_r/1`

  ```
  lib :my_data_source do
    file Path.wildcard("priv/my_data_source_repo/**", match_dot: true)
    file Path.wildcard("test/support/fixtures/my_data_source/**/*.ex")
    template "some/template/for/my_data_source"
  end
  ```

  """
  defmacro lib(name, do: block) do
    opts =
      case block do
        {:__block__, _meta, opts} -> opts
        opt -> [opt]
      end

    quote do
      try do
        import Uniform.Blueprint
        Uniform.Blueprint.__lib__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  @doc false
  defmacro lib(name) do
    quote do
      Uniform.Blueprint.__lib__(__MODULE__, unquote(name), [], @deps_always_block)
    end
  end

  @doc false
  def __lib__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
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

    lib_dep =
      Uniform.LibDep.new!(%{
        name: name,
        lib_deps: opts |> Keyword.get(:lib_deps, []) |> List.wrap(),
        mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap(),
        always: always,
        only: opts[:only],
        except: opts[:except],
        associated_files: associated_files
      })

    Module.put_attribute(mod, :lib_deps, lib_dep)
  end

  @doc """
  Since Uniform is aware of all mix dependencies in `mix.exs`, you don't need
  to tell it about them.

  However, there are two scenarios where you do need to list out mix
  dependencies:

  1. Specifying which mix dependencies should _always_ be ejected. (See
     `Uniform.Blueprint.always/1`.)
  2. Whenever a mix dependency has other mix dependencies. (I.e. Other mix
     packages should always be ejected with it.)

  > #### Including Mix Dependencies in an App {: .info}
  >
  > To eject a mix dependency with a specific app (but not all), make sure to
  > include it as a dependency of lib dependencies (see `lib/2`) or put it in
  > the app's [Uniform Manifest
  > file](./getting-started.html#add-uniform-manifests).

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
        import Uniform.Blueprint, only: [mix_deps: 1]
        Uniform.Blueprint.__mix__(__MODULE__, unquote(name), unquote(opts), @deps_always_block)
      after
        :ok
      end
    end
  end

  @doc false
  defmacro mix(name) do
    quote do
      Uniform.Blueprint.__mix__(__MODULE__, unquote(name), [], @deps_always_block)
    end
  end

  @doc false
  def __mix__(mod, name, opts, always) when is_atom(name) and is_list(opts) do
    mix_dep =
      Uniform.MixDep.new!(%{
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

  @doc """
  In `base_files` and `lib` blocks, `file` is used to specify **files that are
  not in a `lib/` directory** which should be ejected in the app or along with
  the lib.

  > #### Use `Path.wildcard/1` for shorter code {: .tip}
  >
  > Note that `file` can take a path or a list of paths. You can use
  > `Path.wildcard` as in the example below to target multiple files instead
  > of listing them on separate lines.

  ## Options

  `file` takes a `chmod` option, which sets the `mode` for the given `file`
  after it's ejected. See the possible [permission
  options](https://hexdocs.pm/elixir/File.html#chmod/2-permissions).

  ## Examples

      base_files do
        # every ejected app will include these
        file "assets/js/app.js"
        file Path.wildcard("config/**/*.exs")
        file "some/file", chmod: 0o777
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
  In `base_files` and `lib` blocks, `template` is used to specify EEx templates
  that should be rendered and then ejected.

  ## Template Directory and Destination Path

  Uniform templates use a "convention over configuration" model that works like
  this:

  1. At the top of your `Blueprint` module, you specify a template directory
     like this:

      `use Uniform, templates: "lib/uniform/templates"`

  2. Templates must be placed in this directory at the relative path that they
     should be placed in, in the ejected directory.
  3. Templates must have the destination filename, appended with `.eex`.

  > #### Companion guide {: .tip}
  >
  > Consult [Building files from EEx
  > templates](building-files-from-eex-templates.html) for a more detailed look
  > at constructing and effectively using templates for ejection.

  ## Options

  `template` takes a `chmod` option, which sets the `mode` for the rendered
  file after it's ejected. See the possible [permission
  options](https://hexdocs.pm/elixir/File.html#chmod/2-permissions).

  ## Examples

      use Uniform, templates: "priv/uniform-templates"

      base_files do
        # priv/uniform-templates/config/runtime.exs.eex will be rendered, and the
        # result will be placed in `config/runtime.exs` in every ejected app
        template "config/runtime.exs"
      end

      deps do
        lib :datadog do
          # for every app that includes `lib/datadog`,
          # priv/uniform-templates/datadog/prerun.sh.eex will be rendered, and
          # the result will be placed in `datadog/prerun.sh`
          template "datadog/prerun.sh", chmod: 0o555
        end
      end

  """
  def template(path, opts \\ []), do: {:template, {path, opts}}

  @doc """
  `cp_r` works like `cp/2`, but for directory instead of a file.  The directory
  is copied as-is with `File.cp_r!/3`.

  **None of the files are ran through Code Modifiers.**

  This is useful for directories that do not require modification, and contain
  many files.

  For example, the `assets/node_modules` directory in a Phoenix application
  would take ages to copy with `file
  Path.wildcard("assets/node_modules/**/*")`. Instead, use `cp_r
  "assets/node_modules"`.

  ## Examples

      base_files do
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
  `cp` works exactly like `file/2`, except that **no transformations are
  applied to the file**.

  The file is copied as-is with `File.cp!/3`.

  ## Options

  `cp` takes a `chmod` option, which sets the `mode` for the file after it's
  copied. See the possible [permission
  options](https://hexdocs.pm/elixir/File.html#chmod/2-permissions).

  ## Examples

      base_files do
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
  In the `deps` section of your Blueprint, you can specify that a Lib
  Dependency excludes certain files.

  This works much like the `except` option that can be given when importing
  functions with `import/2`.

  In the example below, for any app that depends on `:aws`, every file in
  `lib/aws` and `test/aws` will be ejected except for `lib/aws/hidden_file.ex`.

      deps do
        lib :aws do
          except ["lib/aws/hidden_file.ex"]
        end
      end

  """
  def except(paths), do: {:except, List.wrap(paths)}

  @doc """
  In the `deps` section of your Blueprint, you can specify that a Lib
  Dependency only includes certain files.

  These work much like the `only` option that can be given when importing
  functions with `import/2`.

  In the example below, for any app that depends on `:gcp`, only
  `lib/gcp/necessary_file.ex` will be ejected. Nothing else from `lib/gcp` or
  `test/gcp` will be ejected.

      deps do
        lib :gcp do
          # NOTHING in lib/gcp or test/gcp will be included except these:
          only ["lib/gcp/necessary_file.ex"]
        end
      end

  """
  def only(paths), do: {:only, List.wrap(paths)}
end
