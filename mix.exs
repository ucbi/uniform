defmodule Uniform.MixProject do
  use Mix.Project

  @version "0.6.0"
  @source_url "https://github.com/ucbi/uniform"

  def project do
    [
      app: :uniform,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: "Write less boilerplate and reuse more code in your portfolio of Elixir apps",
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
      {:ex_doc, ">= 0.30.9", only: [:dev, :docs], runtime: false},
      {:sourceror, "~> 0.14"}
    ]
  end

  defp package do
    %{
      maintainers: ["Paul Statezny"],
      licenses: ["Apache-2.0"],
      links: %{
        GitHub: @source_url
      },
      files: ~w(.formatter.exs mix.exs README.md LICENSE CHANGELOG.md lib templates)
    }
  end

  defp docs do
    [
      main: "Uniform",
      logo: "guides/images/jersey.png",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extra_section: "GUIDES",
      extras: [
        "guides/introduction/Getting Started.md",
        "guides/introduction/How It Works.md",
        "guides/introduction/Uniform Manifests (uniform.exs).md",
        "guides/introduction/Dependencies.md",
        "guides/introduction/Code Transformations.md",
        "guides/howtos/Setting up a Phoenix project.md",
        "guides/howtos/Auto-updating ejected codebases.md",
        "guides/howtos/Handling multiple data sources.md",
        "guides/howtos/Building files from EEx templates.md",
        "guides/assessment/Use Cases.md",
        "guides/assessment/Benefits and Disadvantages.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\/.?/,
        "How-To's": ~r/guides\/howtos\/.?/,
        "Assessing the Model": ~r/guides\/assessment\/.?/
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
