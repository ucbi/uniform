defmodule EjectTest do
  use Eject.ProjectCase

  alias Eject.{Project, Manifest, App}

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
    # this is gitignored; we can eject to it without adding to the git index
    # prepare app
    project = %Project{
      base_app: :test_project,
      mix_module: TestProject.MixProject,
      module: TestProject.Eject.Project,
      destination: "../../ejected"
    }

    manifest = %Manifest{lib_deps: [:included_lib], mix_deps: [:included_mix]}
    app = App.new!(project, manifest, Tweeter)

    Eject.eject(app)

    # check for files that are always ejected (read! will crash if missing)
    read!("mix.exs")
    read!("mix.lock")
    read!(".gitignore")
    read!(".formatter.exs")
    read!("test/test_helper.exs")

    # files in {:dir, _} tuples should not be modified
    file_txt = read!("dir/file.txt")
    assert file_txt =~ "TestProject"
    refute file_txt =~ "Tweeter"

    # lib files should be modified
    lib_file = read!("lib/included_lib/included.ex")
    assert lib_file =~ "Tweeter"
    refute lib_file =~ "TestProject"

    # files are created from templates
    template_file = read!("config/runtime.exs")
    assert template_file =~ "1 + 1 = 2"
    assert template_file =~ "App name is tweeter"
    assert template_file =~ "Depends on included_mix"
    refute template_file =~ "Depends on excluded_mix"

    # transformations from modify/0 are ran
    modified_file = read!(".dotfile")
    assert modified_file =~ "[REPLACED LINE WHILE EJECTING Tweeter]"
    refute modified_file =~ "[REPLACE THIS LINE VIA modify/0]"

    # associated_files are included
    assert file_exists?("priv/associated.txt")

    # when `only` option given, only ejects files matching an `only` entry
    # (supported by both lib_deps() and options()[:ejected_app])
    assert file_exists?("lib/with_only/included.txt")
    refute file_exists?("lib/with_only/excluded.txt")
    assert file_exists?("lib/tweeter/included.txt")
    refute file_exists?("lib/tweeter/not_included.txt")
    refute file_exists?("lib/tweeter/excluded.txt")

    # when `except` option given, does not eject files matching `except` entry
    # (supported by both lib_deps() and options()[:ejected_app])
    refute file_exists?("lib/included_lib/excluded.txt")
    refute file_exists?("lib/tweeter/excluded.txt")

    # lib_directory option is able to modify lib directory of a given file
    # (supported by both lib_deps() and options()[:ejected_app])
    assert file_exists?("lib/included_lib_changed/lib_dir_changed.txt")
    assert file_exists?("lib/tweeter_changed/lib_dir_changed.txt")

    # files in `preserve` option are never cleared
    # (note: TestProject.Eject.Project specifies to preserve .gitignore)
    Eject.clear_destination(app)
    read!(".gitignore")
  end
end
