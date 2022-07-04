defmodule TestApp.Project do
  use Eject, templates: "test/support/templates"

  def extra(_app) do
    []
  end

  def lib_deps do
    [
      :indirectly_included_lib,
      :excluded_lib,
      included_lib: [
        mix_deps: [:included_mix],
        lib_deps: [:indirectly_included_lib]
      ]
    ]
  end

  def mix_deps do
    [
      :excluded_mix,
      :indirectly_included_mix,
      included_mix: [
        mix_deps: [:indirectly_included_mix]
      ]
    ]
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
