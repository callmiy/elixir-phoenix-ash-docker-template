defmodule MyAppWeb.Telemetry do
  use Supervisor
  require Logger
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    children =
      if file_path = Application.get_env(:my_app, :telemetry_metrics_consolereporter_file_path) do
        case File.open(file_path, [:write, :append]) do
          {:ok, io_device} ->
            Logger.info([
              "Recording metrics into file: ",
              file_path
            ])

            children ++
              [{Telemetry.Metrics.ConsoleReporter, metrics: metrics(), device: io_device}]

          {:error, reason} ->
            Logger.error([
              "Failed to open telemetry metrics file ",
              file_path,
              ": ",
              inspect(reason)
            ])

            children
        end
      else
        children
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("my_app.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements",
        keep: &keep?/1
      ),
      summary("my_app.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database",
        keep: &keep?/1
      ),
      summary("my_app.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query",
        keep: &keep?/1
      ),
      summary("my_app.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection",
        keep: &keep?/1
      ),
      summary("my_app.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query",
        keep: &keep?/1
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {MyAppWeb, :count_users, []}
    ]
  end

  defp keep?(%{options: options}) when is_list(options) do
    not Keyword.has_key?(options, :oban_conf)
  end

  defp keep?(_) do
    true
  end
end
