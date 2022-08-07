defmodule Mix.Tasks.Uniform.Eject do
  @moduledoc """
  Ejects an [Ejectable App](how-it-works.html#ejectable-apps) to a
  standalone code repository.

  ## Examples

  ```bash
  $ mix uniform.eject Trillo
  $ mix uniform.eject Tweeter --confirm
  $ mix uniform.eject Hatmail --confirm --destination ../../new/dir
  ```

  ## Command line options

    * `--destination` – output directory for the ejected code. Read the
      [Configuration section of the Getting Started
      guide](getting-started.html#configuration) to understand how the
      destination is chosen if this option is omitted.
    * `--confirm` – affirm "yes" to the prompt asking you whether you want to eject.

  ## Ejection Step By Step

  When you eject an app by running `mix uniform.eject MyApp`, the following happens:

  1. The destination directory is created if it doesn't exist.
  2. All files and directories in the destination are deleted, except for `.git`,
    `_build`, and `deps`.
  3. All files in `lib/my_app` and `test/my_app` are copied to the destination.
  4. All files specified in the [base_files](Uniform.Blueprint.html#base_files/1) section of the
     [Blueprint](`Uniform.Blueprint`) are copied to the destination.
  5. All [Lib Dependencies](dependencies.html#lib-dependencies) of the app are
    copied to the destination. This includes all of `lib/dep_name` and
    `test/dep_name` automatically.
  6. For each file copied, [a set of
    transformations](./code-transformations.html) are applied to the file
    contents – except for files specified with `cp` and `cp_r`.
  7. `mix format` is ran on the ejected codebase.

  In step 2, `.git` is kept to preserve the Git repository and history. `deps`
  is kept to avoid having to download all dependencies after ejection. `_build`
  is kept to avoid having to recompile the entire project after ejection.

  In step 7, running `mix format` tidies up things like chains of newlines that
  may appear from applying [Code Fences](code-transformations.html#code-fences).
  It also prevents you from having to think about code formatting in
  [modify](Uniform.Blueprint.html#modify/2).

  """

  use Mix.Task

  @doc false
  def run(args) do
    sample_syntax = "   Syntax is:   mix uniform.eject AppName [--destination path] [--confirm]"

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

        Uniform.ejectables() |> Enum.each(&IO.puts("      #{&1}"))

      _unknown_options ->
        IO.puts("")

        IO.puts(IO.ANSI.red() <> "  Too many options provided." <> sample_syntax)
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp eject_app(app_name, opts) do
    app =
      Uniform.prepare(%{
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        name: "Elixir" |> Module.concat(app_name),
        opts: opts
      })

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
      Uniform.eject(app)
      IO.puts("✅ #{app.name.camel} ejected to #{app.destination}")
    end
  rescue
    e in Uniform.NotEjectableError ->
      message = Uniform.NotEjectableError.message(e)
      IO.puts(IO.ANSI.yellow() <> message <> IO.ANSI.reset())
  end
end
