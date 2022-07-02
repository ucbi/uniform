defmodule Eject.CodeFenceTest do
  use ExUnit.Case

  alias Eject.{App, CodeFence, Manifest, Project}

  setup do
    project = %Project{base_app: :test, module: TestApp.Project}

    manifest =
      Manifest.new!(
        project,
        mix_deps: [:included_mix],
        lib_deps: [:included_lib],
        extra: []
      )

    %{app: App.new!(project, manifest, TestApp)}
  end

  test "eject:lib", %{app: app} do
    output =
      CodeFence.apply_fences(
        """
        defmodule Testing do
          # <eject:lib:included_lib>
          # Keep
          # </eject:lib:included_lib>
          # <eject:lib:excluded_lib>
          # Remove
          # </eject:lib:excluded_lib>
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
  end
end
