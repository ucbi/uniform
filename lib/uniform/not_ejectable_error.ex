defmodule Uniform.NotEjectableError do
  @moduledoc false

  defexception [:app_name, :manifest_path]

  def message(error) do
    """
    There is no ejectable app called #{error.app_name}. Did you misspell it?

    If the name is correct, run this task:

        mix uniform.gen.app #{error.app_name}
    """
  end
end
