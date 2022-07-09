defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.10",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:included_mix, ">= 0.1.0"},
      {:excluded_mix, ">= 0.1.0"},
      {:indirectly_included_mix, ">= 0.1.0"}
    ]
  end
end
