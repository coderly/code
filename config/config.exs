use Mix.Config

# config/config.exs
config :c, C.GitHub.Client,
  adapter: Revolver.Adapters.Hackney,
  host: "https://api.github.com",
  headers: [
    {"accept", "application/vnd.github.v3+json"},
    {"content-type", "application/json"}
  ]

# Configure serializers for automatic encoding/decoding request/response bodies
config :revolver,
  serializers: %{
    "application/json" => Poison,
    "application/vnd.github.v3+json" => Poison
  }
