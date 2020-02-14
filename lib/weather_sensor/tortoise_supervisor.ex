defmodule WeatherSensor.TortoiseSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tortoise.Connection,
        [
          client_id: "weather_sensor",
          handler: {Tortoise.Handler.Logger, []},
          user_name: Application.get_env(:weather_sensor, :broker_user),
          password: Application.get_env(:weather_sensor, :broker_password),
          server: {
            Tortoise.Transport.Tcp,
            host: Application.get_env(:weather_sensor, :broker_host),
            port: Application.get_env(:weather_sensor, :broker_port)
          }
        ]
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
