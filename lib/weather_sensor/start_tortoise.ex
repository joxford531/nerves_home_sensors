defmodule WeatherSensor.StartTortoise do
  use Task

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    Tortoise.Supervisor.start_child(
      client_id: "weather_sensor",
      handler: {Tortoise.Handler.Logger, []},
      server: {Tortoise.Transport.Tcp, host: '10.0.0.3', port: 1883}
    )
  end
end
