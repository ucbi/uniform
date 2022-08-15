defmodule Full.MixProject do
  use Mix.Project

  def project do
    [
      app: :full,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uniform, path: "../../../"},
      # comment to remove
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:graphql_document, "~> 0.2.1"},
      # test that options are retained
      {:sourceror, "~> 0.11.1", path: "../../../deps/sourceror", override: true},
      {:decimal, "~> 2.0"}
    ]
  end
end
