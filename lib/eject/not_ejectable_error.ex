defmodule Eject.NotEjectableError do
  defexception [:app_name, :manifest_path]

  def message(error) do
    "There is no ejectable app called `#{error.app_name}`. To make it ejectable, create: #{error.manifest_path}"
  end
end
