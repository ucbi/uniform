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
    [extra_applications: [:eex, :logger]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.28.4", only: [:dev, :docs], runtime: false}
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
      extra_section: "GUIDES",
      extras: [
        "guides/introduction/Pros and Cons of the Eject Architecture.md",
        "guides/introduction/How It Works.md",
        "guides/introduction/Code Transformations.md",
        "guides/introduction/Getting Started.md",
        "guides/howtos/Specifying Base Files.md",
        "guides/howtos/Bundling Related Dependencies.md",
        "guides/howtos/Building Files from EEx Templates.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\/.?/,
        "How-To's": ~r/guides\/howtos\/.?/
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
