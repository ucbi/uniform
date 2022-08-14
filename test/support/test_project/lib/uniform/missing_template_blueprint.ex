defmodule TestProject.Uniform.MissingTemplateBlueprint do
  use Uniform.Blueprint, templates: "test/support/test_project/templates"

  base_files do
    template "this/template/does/not/exist"
  end

  # prevent config/runtime.exs template from crashing compilation
  import String, only: [upcase: 1]
  def inline_upcase(string), do: String.upcase(string)
end
