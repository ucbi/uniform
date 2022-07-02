defmodule TestApp.Project do
  def extra(_app) do
    []
  end

  def lib_deps do
    [:included_lib, :excluded_lib]
  end

  def mix_deps do
    [:included_mix, :excluded_mix]
  end
end
