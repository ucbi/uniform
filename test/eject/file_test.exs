defmodule Eject.FileTest do
  use Eject.TestProjectCase

  alias Eject.{App, Manifest, Config}

  setup do
    cwd = File.cwd!()

    # set alternative working directory so that Path.wildcard and Path.expand
    # start within the test corral
    File.cd("test/support/test_project")

    # restore working directory
    on_exit(fn -> File.cd(cwd) end)
  end

  setup do
    config = %Config{
      mix_project_app: :test_project,
      mix_project: TestProject.MixProject,
      plan: TestProject.Eject.Plan
    }

    manifest = %Manifest{lib_deps: [:included_lib], mix_deps: [:included_mix]}
    app = App.new!(config, manifest, Tweeter)
    %{app: app}
  end

  test "all_for_app/1 returns all files the app is configured to eject (and only those)", %{
    app: app
  } do
    files = Eject.File.all_for_app(app)

    # expected to be included
    assert Enum.find(files, &match?(%Eject.File{source: ".dotfile"}, &1))

    assert Enum.find(
             files,
             &match?(%Eject.File{source: "config/runtime.exs", type: :template}, &1)
           )

    assert Enum.find(
             files,
             &match?(%Eject.File{source: "lib/included_lib/included.ex"}, &1)
           )

    # not expected to be included
    refute Enum.find(
             files,
             &match?(%Eject.File{source: "lib/excluded_lib" <> _}, &1)
           )
  end
end
