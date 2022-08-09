defmodule Uniform.File do
  @moduledoc """
             Functions for writing files to an ejection destination.

             An `t:Uniform.File.t/0` can be any of the following:

             - A text file to copy with modifications (such as a `.ex`, `.exs`, or `.json` file)
             - A file to copy without modifications (such as a `.png` file)
             - A directory to copy without modifications
             - An EEx template used to generate a file

             """ && false

  alias Uniform.{App, Manifest}

  defstruct [:type, :source, :destination, :chmod]

  @typedoc """
  A file to be ejected. (In true POSIX form, may be a directory, in which case the full contents are copied.)
  """
  @type t :: %__MODULE__{
          type: :text | :template | :cp_r | :cp,
          source: Path.t(),
          destination: Path.t(),
          chmod: nil | non_neg_integer
        }

  #
  # Functions for creating a File struct
  #

  def new(type, %App{} = app, source, opts \\ [])
      when type in [:text, :template, :cp, :cp_r] and is_binary(source) do
    {:module, _} = Code.ensure_loaded(app.internal.config.blueprint)

    destination =
      if function_exported?(app.internal.config.blueprint, :target_path, 2) do
        # call target_path callback, giving the developer a chance to modify the final path
        app.internal.config.blueprint.target_path(source, app)
      else
        source
      end

    path =
      String.replace(
        destination,
        to_string(app.internal.config.mix_project_app),
        app.name.underscore
      )

    struct!(
      __MODULE__,
      type: type,
      source: source,
      destination: Path.join(app.destination, path),
      chmod: opts[:chmod]
    )
  end

  #
  # Functions for gathering all Uniform.Files for a given app
  #

  @doc "Returns all Uniform.Files for the given app."
  @spec all_for_app(App.t()) :: [t]
  def all_for_app(app) do
    # for our purposes, we keep `app_lib_files` last since sometimes the
    # ejected app wants to override phoenix-ish files in `lib/app_name_web`
    # (See `error_view.ex`)
    hardcoded_base_files(app) ++
      base_files(app) ++
      lib_dep_files(app) ++
      app_lib_files(app)
  end

  # Returns all files specified with file/template/cp/cp_r in the `base_files` macro
  def base_files(app) do
    {:module, _} = Code.ensure_loaded(app.internal.config.blueprint)

    if function_exported?(app.internal.config.blueprint, :__base_files__, 1) do
      app
      |> app.internal.config.blueprint.__base_files__()
      |> Enum.flat_map(fn item ->
        case item do
          {type, {path_or_paths, opts}} when type in [:text, :template, :cp, :cp_r] ->
            for path <- List.wrap(path_or_paths), do: new(type, app, path, opts)

          _ ->
            []
        end
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  # Returns hardcoded base files that don't need to be specified
  @spec hardcoded_base_files(App.t()) :: [t]
  defp hardcoded_base_files(app) do
    # If this list changes, update the moduledoc in `Uniform.Blueprint`
    files =
      [
        "mix.exs",
        "mix.lock",
        ".gitignore",
        ".formatter.exs",
        "test/test_helper.exs"
      ]
      |> Enum.filter(&File.exists?/1)

    for path <- files, do: new(:text, app, path)
  end

  # Returns `lib/my_app` ejectables for the app
  @spec app_lib_files(App.t()) :: [t]
  defp app_lib_files(app) do
    manifest_path = Manifest.manifest_path(app.name.underscore)
    {:module, _} = Code.ensure_loaded(app.internal.config.blueprint)

    # never eject the Uniform manifest
    except =
      if function_exported?(app.internal.config.blueprint, :app_lib_except, 1) do
        [manifest_path | app.internal.config.blueprint.app_lib_except(app)]
      else
        [manifest_path]
      end

    lib_dir_files(app, app.name.underscore, except: except)
  end

  # Returns all files required by all the lib deps of this app
  @spec lib_dep_files(App.t()) :: [t]
  defp lib_dep_files(app) do
    Enum.flat_map(app.internal.deps.lib, fn {_, lib_dep} ->
      lib_dir_files(
        app,
        to_string(lib_dep.name),
        Map.take(lib_dep, ~w(only except associated_files)a)
      )
    end)
  end

  # Given a directory, return which paths to eject based on the rules
  # associated with that directory. Includes files in `lib/<lib_dir>`
  # as well as `test/<lib_dir>`
  @spec lib_dir_files(App.t(), String.t(), keyword) :: [Uniform.File.t()]
  defp lib_dir_files(app, lib_dir, opts) do
    # location of lib and test cp_r is configurable for testing
    only = opts[:only]
    except = opts[:except]

    paths = Path.wildcard("lib/#{lib_dir}/**")
    paths = paths ++ Path.wildcard("test/#{lib_dir}/**")
    paths = if only, do: Enum.filter(paths, &filter_path(&1, only)), else: paths
    paths = if except, do: Enum.reject(paths, &filter_path(&1, except)), else: paths
    paths = Enum.reject(paths, &File.dir?/1)

    lib_files = for path <- paths, do: new(:text, app, path)

    associated_files =
      Enum.flat_map(
        opts[:associated_files] || [],
        fn {type, {path_or_paths, opts}} ->
          for path <- List.wrap(path_or_paths), do: new(type, app, path, opts)
        end
      )

    lib_files ++ associated_files
  end

  # returns true if any of the given regexes match or strings match exactly
  @spec filter_path(path :: String.t(), [String.t() | Regex.t()]) :: boolean
  defp filter_path(path, filters) do
    Enum.any?(filters, fn
      %Regex{} = regex -> Regex.match?(regex, path)
      # exact match
      ^path -> true
      _ -> false
    end)
  end

  #
  # Functions for modifying and copying Files to their destination directory
  #

  @doc """
  Given a relative path of a file in your base project, read in the file, send the
  (string) contents along with the `app` to `transform`, and then write it to
  the same directory in the ejected app. (Replacing `my_app` in the path with
  the ejected app's name.)
  """
  def eject!(
        %Uniform.File{source: source, type: type, destination: destination, chmod: chmod},
        app
      ) do
    # ensure the base directory exists before trying to write the file
    dirname = Path.dirname(Path.expand(destination))

    if dirname == destination do
      source
      |> Path.split()
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> Path.join()
      |> File.mkdir_p!()
    else
      File.mkdir_p!(dirname)
    end

    # write the file
    case type do
      :cp_r ->
        File.cp_r!(Path.expand(source), destination)

      :cp ->
        File.cp!(Path.expand(source), destination)

      t when t in [:text, :template] ->
        contents =
          case t do
            :template ->
              template_dir = app.internal.config.blueprint.__template_dir__()

              if !template_dir do
                raise Uniform.MissingTemplatesDirectoryError,
                  template: source,
                  blueprint: app.internal.config.blueprint,
                  mix_project_app: app.internal.config.mix_project_app
              end

              if !File.dir?(Path.expand(template_dir)) do
                raise "String given to `use Uniform.Path, templates: \"...\"` is not a directory (Expands to #{Path.expand(template_dir)})"
              end

              EEx.eval_file(
                Path.join(template_dir, source <> ".eex"),
                app: app,
                depends_on?: &Uniform.App.depends_on?/3
              )

            :text ->
              File.read!(Path.expand(source))
          end

        File.write!(
          destination,
          apply_modifiers(contents, source, app)
        )
    end

    # apply chmod if relevant
    if chmod do
      File.chmod!(destination, chmod)
    end
  end

  @default_modifiers [
    {"mix.exs", &Uniform.Modifiers.remove_unused_mix_deps/2},
    {~r/\.(ex|exs)$/, &Uniform.Modifiers.elixir_code_fences/2},
    {~r/\.(js|ts|jsx|tsx)$/, &Uniform.Modifiers.js_code_fences/2},
    {:all, &Uniform.Modifiers.replace_base_project_name/2}
  ]

  defp apply_modifiers(contents, relative_path, app) do
    # add `Blueprint.modify` transformations to hard-coded default transformations
    modifiers = app.internal.config.blueprint.__modifiers__() ++ @default_modifiers

    Enum.reduce(modifiers, contents, fn {path_or_regex, function}, contents ->
      if apply_modifier?(path_or_regex, relative_path) do
        args =
          case function do
            f when is_function(f, 1) -> [contents]
            f when is_function(f, 2) -> [contents, app]
          end

        apply(function, args)
      else
        contents
      end
    end)
  end

  defp apply_modifier?(:all, _path), do: true
  defp apply_modifier?(%Regex{} = regex, path), do: String.match?(path, regex)
  defp apply_modifier?(path, matching_path), do: path == matching_path
end
