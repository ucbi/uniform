defmodule UniformTest do
  use Uniform.TestProjectCase

  alias Uniform.{Config, Manifest, App}

  defp read!(path) do
    File.read!("../../ejected/tweeter/" <> path)
  end

  defp file_exists?(path) do
    case File.read("../../ejected/tweeter/" <> path) do
      {:ok, _} -> true
      _ -> false
    end
  end

  test "full ejection" do
    # the destination is gitignored; we can eject to it without adding to the git index

    # prepare app
    config = %Config{
      mix_project_app: :test_project,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.Blueprint,
      destination: "../../ejected"
    }

    manifest = %Manifest{lib_deps: [:included_lib]}
    app = App.new!(config, manifest, Tweeter)

    Uniform.eject(app)

    # check for files that are always ejected (read! will crash if missing)
    read!("mix.lock")
    read!(".gitignore")
    read!(".formatter.exs")
    read!("test/test_helper.exs")

    # excluded mix deps are removed; included ones are kept
    mix_exs = read!("mix.exs")
    assert mix_exs =~ "included_mix"
    assert mix_exs =~ "always_included_mix"
    refute mix_exs =~ "excluded_mix"

    # files copied with `dir` should not be modified
    file_txt = read!("dir/file.txt")
    assert file_txt =~ "TestProject"
    refute file_txt =~ "Tweeter"

    # binary files are copied without modification
    assert read!("assets/static/images/pixel.png") ==
             read!("../../support/test_project/assets/static/images/pixel.png")

    # lib files should be modified
    lib_file = read!("lib/included_lib/included.ex")
    assert lib_file =~ "Tweeter"
    refute lib_file =~ "TestProject"

    # files are created from templates for `base_files` and `lib`
    template_file = read!("config/runtime.exs")
    assert template_file =~ "1 + 1 = 2"
    assert template_file =~ "App name is tweeter"
    assert template_file =~ "Depends on included_mix"
    refute template_file =~ "Depends on excluded_mix"

    lib_template = read!("priv/included_lib/template.txt")
    assert lib_template =~ "Template generated for included lib via tweeter"

    # `modify` transformations are ran
    modified_file = read!(".dotfile")
    assert modified_file =~ "[REPLACED LINE WHILE EJECTING Tweeter]"
    refute modified_file =~ "[REPLACE THIS LINE VIA modify]"
    refute modified_file =~ "removed via code fences"
    # test passing function captures (arity 1 and 2) to modify
    assert modified_file =~ "hello world"
    assert modified_file =~ "app name is tweeter"
    assert modified_file =~ "Added to Tweeter in anonymous function capture"

    # associated_files are included
    assert file_exists?("priv/associated.txt")

    # when `only` option given, only ejects files matching an `only` entry
    assert file_exists?("lib/with_only/included.txt")
    refute file_exists?("lib/with_only/excluded.txt")

    # when `except` option given, does not eject files matching `except` entry
    # (supported by both deps and app_lib_except/1)
    refute file_exists?("lib/included_lib/excluded.txt")
    refute file_exists?("lib/always_included_lib/excluded.txt")
    assert file_exists?("lib/tweeter/included.txt")
    refute file_exists?("lib/tweeter/excluded.txt")

    # target_path callback is able to modify path of a given file
    assert file_exists?("lib/included_lib_changed/lib_dir_changed.txt")
    assert file_exists?("lib/tweeter_changed/lib_dir_changed.txt")

    # `preserve`d files are never cleared
    # (note: TestProject.Uniform.Blueprint specifies to preserve .gitignore)
    Uniform.clear_destination(app)
    assert file_exists?(".gitignore")
  end

  test "ejecting with an empty Blueprint" do
    # the destination is gitignored; we can eject to it without adding to the git index
    config = %Config{
      mix_project_app: :test_project,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.EmptyBlueprint,
      destination: "../../ejected"
    }

    manifest = %Manifest{}
    app = App.new!(config, manifest, Tweeter)

    Uniform.eject(app)
  end
end
