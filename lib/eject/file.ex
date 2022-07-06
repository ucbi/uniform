defmodule Eject.File do
  @moduledoc """
  Functions for writing files to an ejection destination.

  An `t:Eject.File.t/0` can be any of the following:

  - A text file to copy (such as a `.ex`, `.exs`, or `.json` file)
  - A directory to copy
  - An EEx template used to generate a file
  - A binary file to copy

  """

  alias Eject.{App, CodeFence, Manifest, MixExs, Rules}

  defstruct [:type, :source, :destination, :chmod]

  @type t :: %__MODULE__{
          type: :text | :template | :dir | :binary,
          source: Path.t(),
          destination: Path.t(),
          chmod: nil | non_neg_integer
        }

  #
  # Functions for gathering all Eject.Files for a given app
  #

  @doc "Returns all Eject.Files for the given app."
  @spec all_for_app(App.t()) :: [t]
  def all_for_app(app) do
    # for our purposes, we keep `app_lib_files` last since sometimes the
    # ejected app wants to override phoenix-ish files in `lib/app_name_web`
    # (See `error_view.ex`)
    base_files(app) ++
      lib_dep_files(app) ++
      app_lib_files(app)
  end

  @doc "Returns `base` ejectables for the app."
  @spec base_files(App.t()) :: [t]
  def base_files(app) do
    project = app.project.module
    base_files = app |> project.base_files() |> List.flatten()

    base_files =
      [
        "mix.exs",
        "mix.lock",
        ".gitignore",
        ".formatter.exs",
        "test/test_helper.exs"
      ]
      |> Enum.filter(&File.exists?/1)
      |> Enum.concat(base_files)

    for file <- base_files, not is_nil(file) do
      {type, path, opts} =
        case file do
          {type, path, opts} when is_atom(type) and is_binary(path) -> {type, path, opts}
          {type, path} when is_atom(type) and is_binary(path) -> {type, path, []}
          {path, opts} when is_binary(path) -> {nil, path, opts}
          path -> {nil, path, []}
        end

      type = type || detect_base_file_type(path)
      file_rules = Rules.new(opts)
      destination = destination(path, app, file_rules)
      %Eject.File{type: type, source: path, destination: destination, chmod: file_rules.chmod}
    end
  end

  # extensions of binary files; these will not go through text-file
  # transformations but will instead be copied over with a `cp` system call
  @binary_extensions ["ico", "jpg", "bmp", "png"]

  defp detect_base_file_type(path) do
    if File.dir?(path) do
      :dir
    else
      if Path.extname(path) in @binary_extensions do
        :binary
      else
        :text
      end
    end
  end

  @doc "Returns `lib/my_app` ejectables for the app."
  @spec app_lib_files(App.t()) :: [t]
  def app_lib_files(app) do
    manifest_path = Manifest.manifest_path(app.name.snake)
    project = app.project.module

    file_rules =
      app
      |> project.options()
      |> Keyword.get(:ejected_app, [])
      # never eject the Eject manifest
      |> Keyword.update(:except, [manifest_path], fn except -> [manifest_path | except] end)
      |> Rules.new()

    for path <- lib_dir_files(app.name.snake, file_rules) do
      %Eject.File{type: :text, source: path, destination: destination(path, app, file_rules)}
    end
  end

  @doc "Returns LibDeps as ejectables."
  @spec lib_dep_files(App.t()) :: [t]
  def lib_dep_files(app) do
    Enum.flat_map(app.deps.lib, fn {_, lib_dep} ->
      for path <- lib_dir_files(to_string(lib_dep.name), lib_dep.file_rules) do
        %Eject.File{
          type: :text,
          source: path,
          destination: destination(path, app, lib_dep.file_rules),
          chmod: lib_dep.file_rules.chmod
        }
      end
    end)
  end

  # Given a directory, return which paths to eject based on the rules
  # associated with that directory. Includes files in `lib/<lib_dir>`
  # as well as `test/<lib_dir>`
  defp lib_dir_files(lib_dir, %Rules{associated_files: extra, only: only, except: except}) do
    # location of lib and test directories is configurable for testing
    paths = Path.wildcard("lib/#{lib_dir}/**")
    paths = paths ++ Path.wildcard("test/#{lib_dir}/**")
    paths = if only, do: Enum.filter(paths, &filter_path(&1, only)), else: paths
    paths = if except, do: Enum.reject(paths, &filter_path(&1, except)), else: paths
    paths = if extra, do: List.flatten(extra) ++ paths, else: paths
    Enum.reject(paths, &File.dir?/1)
  end

  defp destination(path, app, file_rules) do
    destination_relative_path =
      if lib_dir = file_rules.lib_directory do
        if dir = lib_dir.(app, path) do
          path
          |> String.replace(~r/^lib\/[^\/]+\//, "lib/#{dir}/")
          |> String.replace(to_string(app.project.base_app), app.name.snake)
        else
          path
        end
      else
        path
      end

    relative_path =
      String.replace(
        destination_relative_path,
        to_string(app.project.base_app),
        app.name.snake
      )

    Path.join(app.destination, relative_path)
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
      :dir ->
        File.cp_r!(Path.expand(source), destination)

      :binary ->
        File.cp!(Path.expand(source), destination)

      t when t in [:text, :template] ->
        contents =
          case t do
            :template ->
              template_dir = app.project.module.__templates__()

              if !template_dir do
                raise "`use Eject, templates: \"...\"` must specify a templates directory"
              end

              if !File.dir?(Path.expand(template_dir)) do
                raise "String given to `use Eject, templates: \"...\"` is not a directory (Expands to #{Path.expand(template_dir)})"
              end

              EEx.eval_file(
                Path.join(template_dir, source <> ".eex"),
                app: app,
                depends_on?: &Eject.App.depends_on?/3
              )

            :text ->
              File.read!(Path.expand(source))
          end

        snake = to_string(app.project.base_app)

        transformed =
          contents
          # apply specified transformations in `Project.modify`
          |> apply_modifiers(source, app)
          # replace `base_project_name` with `ejected_app_name`
          |> String.replace(snake, app.name.snake)
          # replace `base-project-name` with `ejected-app-name`
          |> String.replace(String.replace(snake, "_", "-"), app.name.kebab)
          # replace `BaseProjectName` with `EjectedAppName`
          |> String.replace(Macro.camelize(snake), app.name.pascal)
          |> CodeFence.apply_fences(app)

        File.write!(destination, transformed)
    end

    # apply chmod if relevant
    if chmod do
      File.chmod!(destination, chmod)
    end
  end

  defp apply_modifiers(contents, relative_path, app) do
    project = app.project.module
    modifiers = project.modify()
    modifiers = [{"mix.exs", &MixExs.remove_unused_deps/2} | modifiers]

    Enum.reduce(modifiers, contents, fn {path_or_regex, modifier}, contents ->
      if apply_modifier?(path_or_regex, relative_path) do
        modifier.(contents, app)
      else
        contents
      end
    end)
  end

  defp apply_modifier?(%Regex{} = regex, path), do: String.match?(path, regex)
  defp apply_modifier?(path, matching_path), do: path == matching_path
end
