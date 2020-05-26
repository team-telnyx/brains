defmodule Brains.MixProject do
  use Mix.Project

  def project do
    [
      app: :brains,
      version: "0.1.3",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/team-telnyx/brains",
      description: description(),
      docs: [
        main: "readme",
        extras: [
          "README.md"
        ]
      ]
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
      {:tesla, "~> 1.3"},
      {:poison, ">= 2.0.0 and < 5.0.0"},

      # Quality-related
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},

      # Docs generation
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Brains is a GraphQL client in Elixir using Tesla
    """
  end

  defp package do
    [
      maintainers: ["Guilherme Balena Versiani <guilherme@telnyx.com>"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/team-telnyx/brains"},
      files: ~w(lib mix.exs README.md LICENSE),
    ]
  end
end
