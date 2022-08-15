defmodule Uniform.ManifestTest do
  use ExUnit.Case
  doctest Uniform.Manifest, import: true

  alias Uniform.{Manifest, Config}

  defmodule Blueprint do
    use Uniform.Blueprint
  end

  defmodule MixProject do
    def project, do: [deps: deps()]
    defp deps, do: [{:included_mix, "0.1.0"}]
  end

  test "new!/2 creates a new Manifest struct" do
    result =
      Manifest.new!(
        %Config{
          mix_project_app: :test,
          mix_project: Uniform.ManifestTest.MixProject,
          blueprint: Uniform.ManifestTest.Blueprint
        },
        mix_deps: [:included_mix],
        lib_deps: [:uniform],
        extra: [foo: [bar: [baz: :qux]]]
      )

    assert %Uniform.Manifest{
             extra: [foo: [bar: [baz: :qux]]],
             lib_deps: [:uniform],
             mix_deps: [:included_mix]
           } = result
  end

  test "new!/2 raises if mix_deps or lib_deps contain unspecified deps" do
    config = %Config{
      mix_project_app: :test,
      mix_project: Uniform.ManifestTest.MixProject,
      blueprint: Uniform.ManifestTest.Blueprint
    }

    assert_raise ArgumentError, fn ->
      Manifest.new!(config, mix_deps: [:unspecified_mix_dep], lib_deps: [], extra: [])
    end

    assert_raise ArgumentError, fn ->
      Manifest.new!(config, mix_deps: [], lib_deps: [:unspecified_lib_dep], extra: [])
    end
  end
end
