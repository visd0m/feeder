defmodule FeederBot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :feeder_bot,
      version: "1.0.4",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {FeederBot, []},
      extra_applications: [
        :logger,
        :logger_file_backend,
        :httpoison,
        :feeder,
        :xmerl
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.12"},
      {:edeliver, "~> 1.4.4"},
      {:logger_file_backend, "~> 0.0.7"},
      {:poison, "~> 3.1"},
      {:quantum, ">= 2.1.0-beta.1"},
      {:amnesia, "~> 0.2.7"},
      {:timex, "~> 3.1"},
      {:feeder_ex, git: "https://github.com/manukall/feeder_ex.git", branch: "master"},
      {:distillery, "~> 1.4", runtime: false, warn_missing: false}
    ]
  end
end
