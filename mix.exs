defmodule Quarp.MixProject do
  use Mix.Project

  def project do
    [
      app: :quarp,
      version: "1.2.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/DriesDeBackker/quarp-reactivity.git"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rp_middleware, "~> 0.1.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:observables_extended, "~> 0.3.5"}
    ]
  end

  defp description() do
    "A library for distributed reactive programming with consistency guarantees in the spirit of 'Quality Aware Reacive Programming for the IoT'.
    Features fifo (no guarantee), (relaxed) glitch-freedom ({:g, margin}) and (relaxed) logical clock synchronization ({:t, margin}) as guarantees."
  end


  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "quarp",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Dries De Backker"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/DriesDeBackker/quarp-reactivity.git"}
    ]
  end
end
