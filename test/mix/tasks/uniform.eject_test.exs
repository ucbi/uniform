defmodule Mix.Tasks.Uniform.EjectTest do
  use ExUnit.Case

  defp eject(project, app_name) do
    System.cmd(
      "mix",
      ["uniform.eject", app_name, "--destination", "../../ejected/#{app_name}", "--confirm"],
      cd: "test/projects/#{project}",
      stderr_to_stdout: true
    )
  end

  test "ejecting with an empty Blueprint" do
    # We don't assert anything but simply test the happy path for crashes.
    {_, 0} = eject("empty", "hatmail")
  end

  test "missing templates directory" do
    {stderr, 1} = eject("missing_template_dir", "trillo")

    assert stderr =~
             """
             ** (Uniform.MissingTemplateDirError) No template directory defined

             Trying to eject template: some/template

             Pass the `templates` option to `use Uniform.Blueprint`

                 defmodule MissingTemplateDir.Uniform.Blueprint do
                   use Uniform.Blueprint, templates: "lib/missing_template_dir/uniform/templates"
                                             ^
                                           this is missing
             """
  end

  test "missing template file" do
    {stderr, 1} = eject("missing_template", "instant_gram")

    assert stderr =~
             """
             ** (Uniform.MissingTemplateError) Template does not exist

                 templates/this/template/does/not/exist.eex

             Did you forget to create the file?
             """
  end

  test "full ejection" do
    {_stdout, 0} = eject("full", "tweeter")

    read! = &File.read!("test/ejected/tweeter/" <> &1)

    exists? = fn path ->
      case File.read("test/ejected/tweeter/" <> path) do
        {:ok, _} -> true
        _ -> false
      end
    end

    # check for files that are always ejected (read! will crash if missing)
    read!.("mix.lock")
    read!.(".gitignore")
    read!.(".formatter.exs")
    read!.("test/test_helper.exs")

    # excluded mix deps are removed; included ones are kept
    mix_exs = read!.("mix.exs")
    # indirectly included via lib in manifest
    assert mix_exs =~ "esbuild"
    # always included via Blueprint
    assert mix_exs =~ "decimal"
    # test that opts are transferred properly
    assert mix_exs =~ "runtime: Mix.env() == :dev"
    refute mix_exs =~ "excluded_mix"
    # removes comments for now instead of moving them all to the top
    refute mix_exs =~ "comment to remove"

    # files copied with `dir` should not be modified
    file_txt = read!.("dir/file.txt")
    assert file_txt =~ "Full"
    refute file_txt =~ "Tweeter"

    # binary files are copied without modification
    assert read!.("assets/static/images/pixel.png") ==
             read!.("../../projects/full/assets/static/images/pixel.png")

    # lib files should be modified
    lib_file = read!.("lib/included_lib/included.ex")
    assert lib_file =~ "Tweeter"
    refute lib_file =~ "Full"

    # files are created from templates for `base_files` and `lib`
    template_file = read!.("config/runtime.exs")
    assert template_file =~ "1 + 1 = 2"
    assert template_file =~ "App name is tweeter"
    assert template_file =~ "Depends on esbuild"
    refute template_file =~ "Depends on lhttpc"
    # test using imported and inline functions
    assert template_file =~ "INLINE UPCASE"
    assert template_file =~ "STRING.UPCASE"

    lib_template = read!.("priv/included_lib/template.txt")
    assert lib_template =~ "Template generated for included lib via tweeter"

    # `modify` transformations are ran
    modified_file = read!.(".dotfile")
    assert modified_file =~ "[REPLACED LINE WHILE EJECTING Tweeter]"
    refute modified_file =~ "[REPLACE THIS LINE VIA modify]"
    refute modified_file =~ "removed via code fences"
    # test passing function captures (arity 1 and 2) to modify
    assert modified_file =~ "hello world"
    assert modified_file =~ "app name is tweeter"
    assert modified_file =~ "Added to Tweeter in anonymous function capture"

    # associated_files are included
    assert exists?.("priv/associated.txt")

    # when `only` option given, only ejects files matching an `only` entry
    assert exists?.("lib/with_only/included.txt")
    refute exists?.("lib/with_only/excluded.txt")

    # when `except` option given, does not eject files matching `except` entry
    # (supported by both deps and app_lib_except/1)
    refute exists?.("lib/included_lib/excluded.txt")
    refute exists?.("lib/always_included_lib/excluded.txt")
    assert exists?.("lib/tweeter/included.txt")
    refute exists?.("lib/tweeter/excluded.txt")

    # target_path callback is able to modify path of a given file
    assert exists?.("lib/included_lib_changed/lib_dir_changed.txt")
    assert exists?.("lib/tweeter_changed/lib_dir_changed.txt")

    # demonstrate that `@preserve`d files are never cleared
    # (note: Full.Uniform.Blueprint specifies to preserve .gitignore)
    app = app("full")
    Mix.Tasks.Uniform.Eject.clear_destination(app)
    assert exists?.(".gitignore")
  end

  # get an `%App{}` in a hacky way from a remote project
  defp app(project) do
    args = [
      "run",
      "-e",
      "Uniform.ejectable_apps() |> hd() |> Map.delete(:__struct__) |> inspect() |> IO.puts()"
    ]

    {stdout, 0} = System.cmd("mix", args, cd: "test/projects/#{project}")
    {map, []} = Code.eval_string(stdout)
    Map.put(map, :__struct__, Uniform.App)
  end
end
