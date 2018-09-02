defmodule AssemblyLine.Mixfile do
  use Mix.Project

  def project do
    [app: :assembly_line,
     version: "1.0.0",
     name: "Assembly Line",
     source_url: "https://github.com/LeakyBucket/assembly_line",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     plt_add_apps: [:gproc],
     preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test],
     description: description(),
     package: package(),
     deps: deps(),
     docs: [main: AssemblyLine]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :gproc]]
  end

  def package do
    [
      maintainers: ["Glen Holcomb"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/LeakyBucket/assembly_line"}
    ]
  end

  def description do
    """
    A light-weight job queue (think DAG) manager.
    """
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:gproc, "~> 0.5.0"},
     {:credo, ">= 0.7.4", only: [:dev, :test], runtime: false},
     {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:excoveralls, "~> 0.5.2", only: :test}]
  end
end
