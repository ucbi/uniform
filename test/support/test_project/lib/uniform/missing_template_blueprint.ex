defmodule TestProject.Uniform.MissingTemplateBlueprint do
  use Uniform.Blueprint, templates: "test/support/test_project/templates"

  base_files do
    template "this/template/does/not/exist"
  end
end
