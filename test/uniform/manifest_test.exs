defmodule Uniform.ManifestTest do
  use Uniform.TestProjectCase
  doctest Uniform.Manifest, import: true

  alias Uniform.{Manifest, Config}

  test "new!/2 creates a new Manifest struct" do
    result =
      Manifest.new!(
        %Config{
          mix_project_app: :test,
          mix_project: TestProject.MixProject,
          blueprint: TestProject.Uniform.Blueprint
        },
        mix_deps: [:included_mix],
        lib_deps: [:included_lib],
        extra: [foo: [bar: [baz: :qux]]]
      )

    assert %Uniform.Manifest{
             extra: [foo: [bar: [baz: :qux]]],
             lib_deps: [:included_lib],
             mix_deps: [:included_mix]
           } = result
  end

  test "new!/2 raises if mix_deps or lib_deps contain unspecified deps" do
    config = %Config{
      mix_project_app: :test,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.Blueprint
    }

    assert_raise ArgumentError, fn ->
      Manifest.new!(config, mix_deps: [:unspecified_mix_dep], lib_deps: [], extra: [])
    end

    assert_raise ArgumentError, fn ->
      Manifest.new!(config, mix_deps: [], lib_deps: [:unspecified_lib_dep], extra: [])
    end
  end
end