defmodule MissingTemplateDir.Uniform.Blueprint do
  use Uniform.Blueprint

  base_files do
    template "some/template"
  end
end
