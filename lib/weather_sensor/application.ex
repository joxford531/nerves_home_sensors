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
        {WeatherSensor.MotionServer, []}
      ] ++ children(target())

    Tortoise.Supervisor.start_child(
      client_id: "weather_sensor",
      handler: {Tortoise.Handler.Logger, []},
      user_name: Application.get_env(:weather_sensor, :broker_user),
      password: Application.get_env(:weather_sensor, :broker_password),
      server: {
        Tortoise.Transport.Tcp,
        host: Application.get_env(:weather_sensor, :broker_host),
        port: Application.get_env(:weather_sensor, :broker_port)
      }
    )

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
