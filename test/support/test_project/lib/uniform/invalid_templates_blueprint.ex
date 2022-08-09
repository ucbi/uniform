defmodule TestProject.Uniform.InvalidTemplatesBlueprint do
  use Uniform.Blueprint, templates: "not/a/real/path"

  base_files do
    template "config/runtime.exs"
  end
end
