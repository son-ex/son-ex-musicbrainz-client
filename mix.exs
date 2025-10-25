defmodule SonExMusicbrainzClient.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/son-ex/son-ex-musicbrainz-client"

  def project do
    [
      app: :son_ex_musicbrainz_client,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "SonEx MusicBrainz Client",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.16", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A lightweight Elixir client for the MusicBrainz API v2.
    Provides interfaces for lookup, browse, and search operations across all MusicBrainz entity types.
    """
  end

  defp package do
    [
      name: "son_ex_musicbrainz_client",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "MusicBrainz API" => "https://musicbrainz.org/doc/MusicBrainz_API"
      },
      maintainers: ["Josh Chernoff <hello@fullstack.ing>"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end
end
