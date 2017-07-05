defmodule C.Mixfile do
  use Mix.Project

  def project do
    [app: :c,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: C.CLI],
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:revolver, github: "scrogson/revolver", ref: "master"},
      {:hackney, "1.6.1"},
      {:poison, "~> 3.0"}
    ]
  end

end
