defmodule Uniform.FileTest do
  use ExUnit.Case

  alias Uniform.{App, Manifest, Config}

  defmodule Blueprint do
    use Uniform.Blueprint, templates: "test/support"

    base_files do
      file "lib/uniform.ex"
      template "template.txt"
    end
  end

  defmodule MixProject do
    def project, do: [deps: deps()]
    defp deps, do: [{:included_mix, "0.1.0"}]
  end

  setup do
    config = %Config{
      mix_project_app: :test,
      mix_project: Uniform.FileTest.MixProject,
      blueprint: Uniform.FileTest.Blueprint
    }

    manifest = %Manifest{lib_deps: [:uniform], mix_deps: [:included_mix]}
    app = App.new!(config, manifest, "tweeter")
    %{app: app}
  end

  test "all_for_app/1 returns all files the app is configured to eject (and only those)", %{
    app: app
  } do
    files = Uniform.File.all_for_app(app)

    # included
    assert Enum.find(files, &match?(%Uniform.File{source: "lib/uniform.ex"}, &1))
    assert Enum.find(files, &match?(%Uniform.File{source: "lib/uniform/app.ex"}, &1))

    assert Enum.find(
             files,
             &match?(%Uniform.File{source: "template.txt", type: :template}, &1)
           )

    # excluded
    refute Enum.find(
             files,
             &match?(%Uniform.File{source: "lib/mix" <> _}, &1)
           )
  end
end
