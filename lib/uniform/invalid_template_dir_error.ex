defmodule Uniform.InvalidTemplateDirError do
  @moduledoc false

  defexception [:directory]

  def message(error) do
    """
    `templates` option is not a directory.

        use Uniform.Blueprint, templates: #{inspect(error.directory)}

    Either create the directory, or change `templates` to point to an existing
    directory.

    """
  end
end
