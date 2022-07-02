defmodule Eject.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ucbi/eject"

  def project do
    [
      app: :eject,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: "A simple alternative to Umbrella and Poncho apps",
      package: package(),

      # Docs
      name: "Eject",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:eex]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.19.0", only: [:dev, :docs], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{
        GitHub: @source_url
      }
    }
  end

  defp docs do
    [
      main: "Eject",
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        "Ejectable Apps": [
          Eject.App,
          Eject.File,
          Eject.Manifest
        ],
        Transformation: [
          Eject.CodeFence,
          Eject.MixExs,
          Eject.Rules
        ],
        Dependencies: [
          Eject.Deps,
          Eject.LibDep,
          Eject.MixDep
        ],
        Errors: [
          Eject.NotEjectableError
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
