defmodule MyApp.SharedConfig do
  import Config

  # runtime
  def start_server? do
    if is_test() do
      false
    else
      process_env_var("PHX_SERVER") != nil
    end
  end

  # runtime
  def endpoint_config do
    # The secret key base is used to sign/encrypt cookies and other secrets.
    # A default value is used in config/dev.exs and config/test.exs but you
    # want to use a different value for prod and you most likely don't want
    # to check this value into version control, so we use an environment
    # variable instead.
    secret_key_base =
      process_env_var("SECRET_KEY_BASE",
        error: """
        --- is missing.
        You can generate one by calling: mix phx.gen.secret
        """
      )

    port = process_env_var("PORT", 4000) |> String.to_integer()

    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
    # for details about using IPv6 vs IPv4 and loopback vs public addresses.
    ip = {0, 0, 0, 0, 0, 0, 0, 0}

    http_config = [
      http: [
        ip: ip,
        port: port
      ]
    ]

    [
      server: start_server?(),
      url: [
        host: phx_host(),
        port: external_access_https_port()
      ],
      secret_key_base: secret_key_base
    ] ++ http_config
  end

  # runtime
  def pool_size do
    if is_test() do
      System.schedulers_online() * 2
    else
      process_env_var("POOL_SIZE", "10")
      |> String.to_integer()
    end
  end

  # runtime
  def database_url do
    url =
      process_env_var("DATABASE_URL",
        error: """
        --- is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """
      )

    if is_test() do
      # Force MIX_TEST_PARTITION in test even if not set by developer.
      url <> process_env_var("MIX_TEST_PARTITION", 1)
    else
      url
    end
  end

  # runtime
  def otel() do
    if is_prod() do
      opentelemetry_exporter_config()
    else
      case process_env_var("OTEL_EXPORTER_BACKEND") do
        nil ->
          []

        "stdout" ->
          stdout_exporter_config()

        "endpoints" ->
          opentelemetry_exporter_config()

        "both" ->
          opentelemetry_exporter_config() ++ stdout_exporter_config()
      end
    end
  end

  # runtime
  def telemetry_metrics_consolereporter_file_path() do
    if is_prod() do
      nil
    else
      process_env_var("TELEMETRY_METRICS_CONSOLEREPORTER_FILE_PATH")
    end
  end

  # runtime
  def log_format() do
    if process_env_var("LOG_APP_DATETIME") do
      "$date $time [$level] $metadata $message\n"
    else
      "[$level] $metadata $message\n"
    end
  end

  defp is_test do
    config_env() == :test
  end

  defp is_prod do
    config_env() == :prod
  end

  defp stdout_exporter_config do
    [
      otel_batch_processor: %{
        exporter: {
          :otel_exporter_stdout,
          []
        }
      }
    ]
  end

  defp opentelemetry_exporter_config() do
    port =
      process_env_var("OTEL_EXPORTER_PORT", 4318)
      |> String.to_integer()

    [
      otel_batch_processor: %{
        exporter: {
          :opentelemetry_exporter,
          %{
            endpoints: [
              {
                :http,
                process_env_var("OTEL_EXPORTER_HOSTNAME", "otel"),
                port,
                []
              }
            ]
          }
        }
      }
    ]
  end

  defp phx_host do
    process_env_var("PHX_HOST", error: "---  PHX_HOST is missing.")
  end

  defp external_access_https_port do
    process_env_var("EXTERNAL_ACCESS_HTTPS_PORT", 443) |> String.to_integer()
  end

  defp process_env_var(variable_name, opts \\ [])

  defp process_env_var(variable_name, opt) when not is_list(opt) do
    process_env_var(variable_name, default: to_string(opt))
  end

  defp process_env_var(variable_name, opts) do
    default = Keyword.get(opts, :default)

    error =
      case Keyword.get(opts, :error) do
        nil ->
          nil

        error ->
          String.replace(error, "--- ", "Environment variable #{variable_name} ")
      end

    case System.get_env(variable_name, "") |> String.trim() do
      "" ->
        if error do
          raise error
        else
          default
        end

      val ->
        val
    end
  end
end
