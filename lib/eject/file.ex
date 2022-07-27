defmodule Eject.File do
  @moduledoc """
             Functions for writing files to an ejection destination.

             An `t:Eject.File.t/0` can be any of the following:

             - A text file to copy with modifications (such as a `.ex`, `.exs`, or `.json` file)
             - A file to copy without modifications (such as a `.png` file)
             - A directory to copy without modifications
             - An EEx template used to generate a file

             """ && false

  alias Eject.{App, CodeFence, Manifest, Rules}

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

  def new(type, %App{} = app, source, rules \\ nil)
      when type in [:text, :template, :cp, :cp_r] and is_binary(source) do
    path =
      source
      # call target_path callback, giving the developer a chance to modify the final path
      |> app.internal.config.plan.target_path(app)
      |> String.replace(to_string(app.internal.config.mix_project_app), app.name.underscore)

    struct!(
      __MODULE__,
      type: type,
      source: source,
      destination: Path.join(app.destination, path),
      chmod: rules && rules.chmod
    )
  end

  #
  # Functions for gathering all Eject.Files for a given app
  #

  @doc "Returns all Eject.Files for the given app."
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

  # Returns all files specified with file/template/cp/cp_r in the `eject` macro
  def base_files(app) do
    app
    |> app.internal.config.plan.__eject__()
    |> Enum.flat_map(fn item ->
      case item do
        {type, {path_or_paths, opts}} when type in [:text, :template, :cp, :cp_r] ->
          rules = Rules.new(opts)
          for path <- List.wrap(path_or_paths), do: new(type, app, path, rules)

        _ ->
          []
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Returns hardcoded base files that don't need to be specified
  @spec hardcoded_base_files(App.t()) :: [t]
  defp hardcoded_base_files(app) do
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

    file_rules =
      app
      |> app.internal.config.plan.__eject__()
      # never eject the Eject manifest
      |> Keyword.update(:except, [manifest_path], fn except -> [manifest_path | except] end)
      |> Keyword.take([:except])
      |> Rules.new()

    lib_dir_files(app, app.name.underscore, file_rules)
  end

  # Returns all files required by all the lib deps of this app
  @spec lib_dep_files(App.t()) :: [t]
  defp lib_dep_files(app) do
    Enum.flat_map(app.internal.deps.lib, fn {_, lib_dep} ->
      lib_dir_files(app, to_string(lib_dep.name), lib_dep.file_rules)
    end)
  end

  # Given a directory, return which paths to eject based on the rules
  # associated with that directory. Includes files in `lib/<lib_dir>`
  # as well as `test/<lib_dir>`
  @spec lib_dir_files(App.t(), String.t(), Rules.t()) :: [Eject.File.t()]
  defp lib_dir_files(
         app,
         lib_dir,
         %Rules{only: only, except: except} = rules
       ) do
    # location of lib and test cp_r is configurable for testing
    paths = Path.wildcard("lib/#{lib_dir}/**")
    paths = paths ++ Path.wildcard("test/#{lib_dir}/**")
    paths = if only, do: Enum.filter(paths, &filter_path(&1, only)), else: paths
    paths = if except, do: Enum.reject(paths, &filter_path(&1, except)), else: paths
    paths = Enum.reject(paths, &File.dir?/1)

    lib_files = for path <- paths, do: new(:text, app, path, rules)

    associated_files =
      Enum.flat_map(
        rules.associated_files || [],
        fn {type, {path_or_paths, opts}} ->
          rules = Rules.new(opts)
          for path <- List.wrap(path_or_paths), do: new(type, app, path, rules)
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
  (string) contents along with the `app` to `transform`, and then write
  it to the same directory in the ejected project. (Replacing `my_app` in
  the path with the ejected app's name.)
  """
  def eject!(%Eject.File{source: source, type: type, destination: destination, chmod: chmod}, app) do
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
              template_dir = app.internal.config.plan.__template_dir__()

              if !template_dir do
                raise "`use Eject.Path, templates: \"...\"` must specify a templates directory"
              end

              if !File.dir?(Path.expand(template_dir)) do
                raise "String given to `use Eject.Path, templates: \"...\"` is not a directory (Expands to #{Path.expand(template_dir)})"
              end

              EEx.eval_file(
                Path.join(template_dir, source <> ".eex"),
                app: app,
                depends_on?: &Eject.App.depends_on?/3
              )

            :text ->
              File.read!(Path.expand(source))
          end

        underscore = to_string(app.internal.config.mix_project_app)

        transformed =
          contents
          # apply specified transformations in `Project.modify`
          |> apply_modifiers(source, app)
          # replace `base_project_name` with `ejected_app_name`
          |> String.replace(underscore, app.name.underscore)
          # replace `base-project-name` with `ejected-app-name`
          |> String.replace(String.replace(underscore, "_", "-"), app.name.hyphen)
          # replace `BaseProjectName` with `EjectedAppName`
          |> String.replace(Macro.camelize(underscore), app.name.camel)
          |> CodeFence.apply_fences(app)

        File.write!(destination, transformed)
    end

    # apply chmod if relevant
    if chmod do
      File.chmod!(destination, chmod)
    end
  end

  @default_modifier {"mix.exs", {Eject.Modifiers, :remove_unused_mix_deps}}

  defp apply_modifiers(contents, relative_path, app) do
    modifiers = app.internal.config.plan.__modifiers__()
    modifiers = [@default_modifier | modifiers]

    Enum.reduce(modifiers, contents, fn {path_or_regex, {module, function}}, contents ->
      if apply_modifier?(path_or_regex, relative_path) do
        apply(module, function, [contents, app])
      else
        contents
      end
    end)
  end

  defp apply_modifier?(%Regex{} = regex, path), do: String.match?(path, regex)
  defp apply_modifier?(path, matching_path), do: path == matching_path
end
