defmodule Uniform.ModifiersTest do
  use ExUnit.Case

  alias Uniform.{App, Modifiers, Manifest, Config}

  defmodule Blueprint do
    use Uniform.Blueprint
  end

  defmodule MixProject do
    def project, do: [deps: deps()]
    defp deps, do: [{:included_mix, "0.1.0"}, {:excluded_mix, "0.1.0"}]
  end

  setup do
    config = %Config{
      mix_project_app: :test,
      mix_project: Uniform.ModifiersTest.MixProject,
      blueprint: Uniform.ModifiersTest.Blueprint
    }

    manifest = %Manifest{
      mix_deps: [:included_mix],
      lib_deps: [:uniform],
      extra: []
    }

    %{app: App.new!(config, manifest, "eject_fence_app")}
  end

  test "uniform:lib", %{app: app} do
    output =
      Modifiers.elixir_eject_fences(
        """
        defmodule Testing do
          # uniform:lib:uniform
          # Keep
          # /uniform:lib:uniform
          # uniform:lib:mix
          # Remove
          # /uniform:lib:mix
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
      Modifiers.elixir_eject_fences(
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
    :eject_fence_app
    :another_app

    output =
      Modifiers.elixir_eject_fences(
        """
        defmodule Testing do
          # uniform:app:eject_fence_app
          # Keep
          # /uniform:app:eject_fence_app
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
      Modifiers.elixir_eject_fences(
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
