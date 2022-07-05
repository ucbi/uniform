defmodule Eject.FileTest do
  use ExUnit.Case, async: true

  alias Eject.{App, File, Manifest, Project}

  setup do
    project = %Project{base_app: :test_app, module: TestApp.Project}
    manifest = %Manifest{lib_deps: [:included_lib], mix_deps: [:included_mix]}
    app = App.new!(project, manifest, Tweeter)
    %{app: app}
  end

  test "all_for_app/1 returns all files the app is configured to eject (and only those)", %{
    app: app
  } do
    files = File.all_for_app(app)

    # expected to be included
    assert Enum.find(files, &match?(%File{source: "test/support/.dotfile"}, &1))
    assert Enum.find(files, &match?(%File{source: "config/runtime.exs", type: :template}, &1))

    assert Enum.find(
             files,
             &match?(%File{source: "test/support/lib/included_lib/included.ex"}, &1)
           )

    # not expected to be included
    refute Enum.find(files, &match?(%File{source: "test/support/lib/excluded_lib" <> _}, &1))
  end
end
