defmodule Eject.ModifiersTest do
  use Eject.TestProjectCase

  alias Eject.{App, Modifiers, Manifest, Config}

  setup do
    config = %Config{
      mix_project_app: :test,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Eject.Blueprint
    }

    manifest =
      Manifest.new!(
        config,
        mix_deps: [:included_mix],
        lib_deps: [:included_lib],
        extra: []
      )

    %{app: App.new!(config, manifest, CodeFenceApp)}
  end

  test "eject:lib", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # eject:lib:included_lib
          # Keep
          # /eject:lib:included_lib
          # eject:lib:excluded_lib
          # Remove
          # /eject:lib:excluded_lib
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "eject:mix", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # eject:mix:included_mix
          # Keep
          # /eject:mix:included_mix
          # eject:mix:excluded_mix
          # Remove
          # /eject:mix:excluded_mix
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "eject:app", %{app: app} do
    # prime String.to_existing_atom
    :code_fence_app
    :another_app

    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # eject:app:code_fence_app
          # Keep
          # /eject:app:code_fence_app
          # eject:app:another_app
          # Remove
          # /eject:app:another_app
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "eject:remove", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # Keep
          # eject:remove
          # Remove
          # /eject:remove
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end
end
