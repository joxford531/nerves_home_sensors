defmodule WeatherSensor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeatherSensor.Supervisor]
    children =
      [
        {WeatherSensor.WeatherServer, []},
        {WeatherSensor.TortoiseSupervisor, []}
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: WeatherSensor.Worker.start_link(arg)
      # {WeatherSensor.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: WeatherSensor.Worker.start_link(arg)
      # {WeatherSensor.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:weather_sensor, :target)
  end
end
