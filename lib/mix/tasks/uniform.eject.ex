defmodule Mix.Tasks.Uniform.Eject do
  @moduledoc """
  Ejects an [Ejectable App](how-it-works.html#ejectable-apps) to a
  standalone code repository.

  ## Usage

  ```bash
  $ mix uniform.eject trillo
  $ mix uniform.eject tweeter --confirm
  $ mix uniform.eject hatmail --confirm --destination ../../new/dir
  ```

  ## Command line options

    * `--destination` – output directory for the ejected code. Read the
      [Configuration section of the Getting Started
      guide](getting-started.html#configuration) to understand how the
      destination is chosen if this option is omitted.
    * `--confirm` – affirm "yes" to the prompt asking you whether you want to eject.

  ## Which files get ejected

  When you run `mix uniform.eject my_app`, these four rules determine which files
  are copied.

  1. [A few files](Uniform.Blueprint.html#module-files-that-are-always-ejected)
     common to Elixir projects are copied.
  2. All files in the Blueprint's
     [base_files](Uniform.Blueprint.html#base_files/1) section are copied.
  3. All files in `lib/my_app` and `test/my_app` are copied.
  4. For every [Lib Dependency](dependencies.html#lib-dependencies) of `my_app`:
      - All files in `lib/my_lib_dep` and `test/my_lib_dep` are copied.
      - All [associated files](Uniform.Blueprint.html#lib/2-associated-files)
        tied to the Lib Dependency are copied.

  > If you need to apply exceptions to these rules, you can use these tools.
  >
  >   - Files in `(lib|test)/my_app` (rule 3) are subject to the
  >     [lib_app_except](Uniform.Blueprint.html#c:app_lib_except/1) callback.
  >   - Lib Dependency files (rule 4) are subject to
  >     [only](Uniform.Blueprint.html#only/1) and
  >     [except](Uniform.Blueprint.html#except/1) instructions.

  ## Ejection step by step

  When you eject an app by running `mix uniform.eject my_app`, the following happens:

  1. The destination directory is created if it doesn't exist.
  2. All files and directories in the destination are deleted, except for
     `.git`, `_build`, `deps`, and anything in the Blueprint's
     [`@preserve`](Uniform.Blueprint.html#module-preserving-files).
  3. All files required by the app are copied to the destination. (See [Which
     files get ejected](#module-which-files-get-ejected).)
  4. For each file copied, [a set of
     transformations](./code-transformations.html) are applied to the file
     contents – except for files specified with `cp` and `cp_r`.
  5. `mix deps.clean --unlock --unused` is ran so that unused Mix Dependencies
     are removed `mix.lock`.
  6. `mix format` is ran on the ejected codebase.

  In step 2, `.git` is kept to preserve the Git repository and history. `deps`
  is kept to avoid having to download all dependencies after ejection. `_build`
  is kept to avoid having to recompile the entire project after ejection.

  In step 6, running `mix format` tidies up things like chains of newlines that
  may appear from applying [Code Fences](code-transformations.html#code-fences).
  It also prevents you from having to think about code formatting in
  [modify](Uniform.Blueprint.html#modify/2).

  """

  use Mix.Task
  require Logger

  @doc false
  def run(args) do
    sample_syntax = "   Syntax is:   mix uniform.eject app_name [--destination path] [--confirm]"

    args
    |> OptionParser.parse!(strict: [destination: :string, confirm: :boolean])
    |> case do
      {opts, [app_name]} ->
        eject_app(app_name, opts)

      {_opts, []} ->
        IO.puts("")
        IO.puts(IO.ANSI.red() <> "  No app name provided." <> sample_syntax)
        IO.puts(IO.ANSI.yellow())
        IO.puts("  Available apps:")

        Uniform.ejectable_app_names() |> Enum.each(&IO.puts("      #{&1}"))

      _unknown_options ->
        IO.puts("")

        IO.puts(IO.ANSI.red() <> "  Too many options provided." <> sample_syntax)
    end
  end

  defp eject_app(app_name, opts) do
    app = Uniform.prepare(%{name: app_name, opts: opts})

    IO.puts("")
    IO.puts("🗺  Ejecting [#{app.name.camel}] to [#{app.destination}]")
    IO.puts("")
    IO.puts("🤖 Mix Dependencies")

    app.internal.deps.included.mix
    |> Enum.chunk_every(6)
    |> Enum.each(fn mix_deps ->
      IO.puts("   " <> Enum.join(mix_deps, " "))
    end)

    if Enum.empty?(app.internal.deps.included.mix) do
      IO.puts("   " <> "[NONE]")
    end

    IO.puts("")
    IO.puts("🤓 Lib Dependencies")

    app.internal.deps.included.lib
    |> Enum.chunk_every(6)
    |> Enum.each(fn lib_deps ->
      IO.puts("   " <> Enum.join(lib_deps, " "))
    end)

    if Enum.empty?(app.internal.deps.included.lib) do
      IO.puts("   " <> "[NONE]")
    end

    IO.puts("")

    if Enum.any?(app.extra) do
      IO.puts("📰 Extra:")

      app.extra
      |> inspect()
      |> Code.format_string!()
      |> to_string()
      |> String.replace(~r/^/m, "   ")
      |> IO.puts()
    end

    unless Keyword.get(opts, :confirm) == true do
      IO.puts("")

      IO.puts(
        IO.ANSI.yellow() <>
          "    ⚠️  Warning: contents of the destination directory will be deleted" <>
          IO.ANSI.reset()
      )
    end

    eject =
      if Keyword.get(opts, :confirm) == true do
        true
      else
        Mix.shell().yes?("\n\nClear destination directory and eject?")
      end

    if eject do
      IO.puts("")
      eject(app)
      IO.puts("✅ #{app.name.camel} ejected to #{app.destination}")
    end
  rescue
    e in Uniform.NotEjectableError ->
      message = Uniform.NotEjectableError.message(e)
      IO.puts(IO.ANSI.yellow() <> message <> IO.ANSI.reset())
  end

  # Ejects an app. Deletes the files in the destination and copies a fresh set
  # of files for the app.
  defp eject(app) do
    clear_destination(app)
    Logger.info("📂 #{app.destination}")
    File.mkdir_p!(app.destination)

    for file <- Uniform.File.all_for_app(app) do
      Logger.info("💾 [#{file.type}] #{file.destination}")
      Uniform.File.eject!(file, app)
    end

    # remove mix deps that are not needed for this project from mix.lock
    System.cmd("mix", ["deps.clean", "--unlock", "--unused"], cd: app.destination)
    System.cmd("mix", ["format"], cd: app.destination)
  end

  # Clear the destination folder where the app will be ejected.
  @doc false
  def clear_destination(app) do
    if File.exists?(app.destination) do
      {:module, _} = Code.ensure_loaded(app.internal.config.blueprint)

      preserve = app.internal.config.blueprint.__preserve__()
      preserve = [".git", "deps", "_build" | preserve]

      app.destination
      |> File.ls!()
      |> Enum.reject(&(&1 in preserve))
      |> Enum.each(fn file_or_folder ->
        path = Path.join(app.destination, file_or_folder)
        Logger.info("💥 #{path}")
        File.rm_rf(path)
      end)
    end
  end
end
