import Config

# Configuration for SonEx.MusicBrainz client
#
# This file provides example configuration for the MusicBrainz API client.
# Copy and modify these settings in your application's config files.

# Example configuration (commented out by default)
#
# config :son_ex_musicbrainz_client,
#   # Required: Meaningful User-Agent identifying your application
#   user_agent: "MyApp/1.0.0 (contact@example.com)",
#
#   # Optional: HTTP options passed to Req
#   http_options: [
#     retry: :transient,
#     max_retries: 3,
#     receive_timeout: 15_000,
#     pool_timeout: 5_000
#   ]

# Import environment-specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
