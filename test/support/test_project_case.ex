defmodule Uniform.TestProjectCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Uniform.TestProjectCase
    end
  end

  setup do
    cwd = File.cwd!()

    # set alternative working directory so that Path.wildcard and Path.expand
    # start within the test corral
    File.cd("test/support/test_project")

    set_blueprint_in_config(TestProject.Uniform.Blueprint)

    # restore working directory
    on_exit(fn -> File.cd(cwd) end)
  end

  def set_blueprint_in_config(blueprint) do
    Application.put_env(
      :test_project,
      Uniform,
      blueprint: blueprint,
      destination: "../../ejected"
    )
  end
end
