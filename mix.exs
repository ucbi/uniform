defmodule Uniform.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ucbi/uniform"

  def project do
    [
      app: :uniform,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: "A simple alternative to Umbrella and Poncho apps",
      package: package(),

      # Docs
      name: "Uniform",
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
      main: "Uniform",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extra_section: "GUIDES",
      extras: [
        "guides/introduction/Getting Started.md",
        "guides/uniformsystem/How It Works.md",
        "guides/uniformsystem/Dependencies.md",
        "guides/uniformsystem/Code Transformations.md",
        "guides/howtos/Setting up a Phoenix project.md",
        "guides/howtos/Handling Multiple Databases.md",
        "guides/howtos/Building files from EEx templates.md",
        "guides/assessment/Use Cases.md",
        "guides/assessment/Benefits and Disadvantages.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\/.?/,
        "The Uniform System": ~r/guides\/uniformsystem\/.?/,
        "How-To's": ~r/guides\/howtos\/.?/,
        "Assessing the Model": ~r/guides\/assessment\/.?/
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
