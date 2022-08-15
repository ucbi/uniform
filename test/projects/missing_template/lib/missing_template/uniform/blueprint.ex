defmodule MissingTemplate.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "templates"

  base_files do
    template "this/template/does/not/exist"
  end
end
