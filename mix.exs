defmodule PhoenixEmailPreferences.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_email_preferences,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PhoenixEmailPreferences.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Peer dependencies - provided by consuming app
      {:phoenix_live_view, ">= 0.20.0", optional: true},
      {:ecto, ">= 3.10.0", optional: true},
      {:ecto_sql, ">= 3.10.0", optional: true},

      # Dev/test only
      {:igniter, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end
end
