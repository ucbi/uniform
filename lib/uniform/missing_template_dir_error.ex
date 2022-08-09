defmodule Uniform.MissingTemplateDirError do
  @moduledoc false

  defexception [:mix_project_app, :template, :blueprint]

  def message(error) do
    """
    No template directory defined.

    Trying to eject template: #{error.template}

    Pass the `templates` option to `use Uniform.Blueprint`

        defmodule #{inspect(error.blueprint)} do
          use Uniform.Blueprint, templates: "lib/#{error.mix_project_app}/uniform/templates"
                                    ^
                                  this is missing

    """
  end
end
