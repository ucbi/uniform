defmodule Uniform.ModifiersTest do
  use Uniform.TestProjectCase

  alias Uniform.{App, Modifiers, Manifest, Config}

  setup do
    config = %Config{
      mix_project_app: :test,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.Blueprint
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

  test "uniform:lib", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # uniform:lib:included_lib
          # Keep
          # /uniform:lib:included_lib
          # uniform:lib:excluded_lib
          # Remove
          # /uniform:lib:excluded_lib
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "uniform:mix", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # uniform:mix:included_mix
          # Keep
          # /uniform:mix:included_mix
          # uniform:mix:excluded_mix
          # Remove
          # /uniform:mix:excluded_mix
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "uniform:app", %{app: app} do
    # prime String.to_existing_atom
    :code_fence_app
    :another_app

    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # uniform:app:code_fence_app
          # Keep
          # /uniform:app:code_fence_app
          # uniform:app:another_app
          # Remove
          # /uniform:app:another_app
        end
        """,
        app
      )

    assert output =~ "Keep"
    refute output =~ "Remove"
    # code fences themselves are always removed
    refute output =~ "eject"
  end

  test "uniform:remove", %{app: app} do
    output =
      Modifiers.elixir_code_fences(
        """
        defmodule Testing do
          # Keep
          # uniform:remove
          # Remove
          # /uniform:remove
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
