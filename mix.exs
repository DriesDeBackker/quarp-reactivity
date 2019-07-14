defmodule Quarp.MixProject do
  use Mix.Project

  def project do
    [
      app: :quarp,
      version: "0.3.1",
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
    [
      mod: {ReactiveMiddleware.Application, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:observables_extended, "~> 0.1.0"}
    ]
  end

  defp description() do
    "A library for distributed reactive programming with consistency guarantees in the spirit of Quarp.
    Features fifo (no guarantee), glitch-freedom and logical clock synchronization as guarantees."
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
