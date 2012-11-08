defmodule ExUnitAnsi.Mixfile do
  use Mix.Project

  def project do
    [ app: :ex_unit_ansi,
      version: "0.0.1",
      deps: deps ]
  end

  def application do
    [applications: [:ansiex, :eisatty]]
  end

  defp deps do
    [ 
      {:ansiex, github: "yrashk/ansiex"},
      {:eisatty, github: "yrashk/eisatty"},
    ]
  end
end
