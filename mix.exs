defmodule Dropkick.MixProject do
  use Mix.Project

  def project do
    [
      app: :dropkick,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      xref: [exclude: [:hackney_request]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Dropkick.Application, []},
      extra_applications: [:logger, :inets]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ecto, "~> 3.0"},
      {:plug, "~> 1.0"},
      {:exvcr, "~> 0.13.5", only: :test},
      {:image, "~> 0.30.0"}
    ]
  end
end
