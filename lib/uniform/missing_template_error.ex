defmodule Uniform.MissingTemplateError do
  @moduledoc false

  defexception [:source, :templates_dir]

  def message(error) do
    """
    Template does not exist

        #{Path.join(error.templates_dir, error.source)}.eex

    Did you forget to create the file?
    """
  end
end
