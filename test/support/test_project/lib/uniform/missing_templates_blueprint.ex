defmodule TestProject.Uniform.MissingTemplatesBlueprint do
  use Uniform.Blueprint

  base_files do
    template "config/runtime.exs"
  end
end
