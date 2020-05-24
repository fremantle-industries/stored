defmodule Stored.MixProject do
  use Mix.Project

  def project do
    [
      app: :stored,
      version: "0.0.6",
      elixir: "~> 1.10",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "Store & retrieve structs against various backends with a simple lightweight API."
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Alex Kwiatkowski"],
      links: %{"GitHub" => "https://github.com/rupurt/stored"}
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
