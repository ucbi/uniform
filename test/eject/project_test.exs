defmodule Eject.ProjectTest do
  use Eject.ProjectCase

  alias Eject.{LibDep, MixDep, Project}

  setup do
    project = %Project{
      base_app: :test_project,
      mix_module: TestProject.MixProject,
      module: TestProject.Eject.Project
    }

    %{project: project}
  end

  test "lib_deps/1", %{project: project} do
    assert %LibDep{
             lib_deps: [:indirectly_included_lib, :with_only],
             mix_deps: [:included_mix]
           } = Project.lib_deps(project).included_lib

    assert %LibDep{lib_deps: [], mix_deps: []} = Project.lib_deps(project).indirectly_included_lib
    assert %LibDep{lib_deps: [], mix_deps: []} = Project.lib_deps(project).excluded_lib
  end

  test "mix_deps/1", %{project: project} do
    assert %MixDep{
             mix_deps: [:indirectly_included_mix]
           } = Project.mix_deps(project).included_mix

    assert %MixDep{mix_deps: []} = Project.mix_deps(project).indirectly_included_mix
    assert %MixDep{mix_deps: []} = Project.mix_deps(project).excluded_mix
  end
end
