defmodule EjectTest do
  use ExUnit.Case, async: true

  alias Eject.{Project, Manifest, App}

  @destination "test/support/ejected"

  defp read!(path) do
    File.read!(@destination <> "/" <> path)
  end

  test "full ejection" do
    # this is gitignored; we can eject to it without adding to the git index
    # prepare app
    project = %Project{base_app: :test_app, module: TestApp.Project, destination: @destination}
    manifest = %Manifest{lib_deps: [:included_lib], mix_deps: [:included_mix]}
    app = App.new!(project, manifest, TwitterClone)

    Eject.eject(app)

    # files in test/support/dir should not be modified
    file_txt = read!("twitter_clone/test/support/dir/file.txt")
    assert file_txt =~ "TestApp"
    refute file_txt =~ "TwitterClone"

    # lib files should be modified
    lib_file = read!("twitter_clone/test/support/lib/included_lib/included.ex")
    assert lib_file =~ "TwitterClone"
    refute lib_file =~ "TestApp"

    # files are created from templates
    template_file = read!("twitter_clone/config/runtime.exs")
    assert template_file =~ "1 + 1 = 2"
    assert template_file =~ "App name is twitter_clone"
    assert template_file =~ "Depends on included_mix"
    refute template_file =~ "Depends on excluded_mix"
  end
end
