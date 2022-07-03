defmodule TestApp.Project do
  use Eject, templates: "test/support/templates"

  def extra(_app) do
    []
  end

  def lib_deps do
    [:included_lib, :excluded_lib]
  end

  def mix_deps do
    [:included_mix, :excluded_mix]
  end

  def base_files(_app) do
    [
      {:dir, "assets"},
      {:template, "config/runtime.exs"},
      ".credo.exs"
    ]
  end

  def modify do
    []
  end

  def options(_app) do
    []
  end
end
