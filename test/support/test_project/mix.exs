defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: "0.1.0",
      elixir: "~> 1.10",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.19.0", only: [:dev, :docs], runtime: false}
    ]
  end
end
