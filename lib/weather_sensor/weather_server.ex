defmodule WeatherSensor.WeatherServer do
  use GenServer
  require Logger
  alias WeatherSensor.Sht31Sensor

  def start_link(_) do
    Logger.info("Starting Weather Server")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    ref = Sht31Sensor.start()
    schedule_collection()
    {:ok, ref}
  end

  @impl true
  def handle_info(:collect, ref) do
    utc_time = DateTime.utc_now()
    timezone = Application.get_env(:weather_sensor, :timezone)
    {:ok, humidity, temp} = Sht31Sensor.read_temp_humidity(ref)

    humidity = Float.round(humidity, 1)

    temp_f =
      Sht31Sensor.celsius_to_fahrenheit(temp)
      |> Float.round(1)

    dew_point =
      Sht31Sensor.calculate_dewpoint(humidity, temp)
      |> Sht31Sensor.celsius_to_fahrenheit()
      |> Float.round(1)

    Tortoise.publish("weather_sensor", "front/temp_humidity",
      Jason.encode!(%{
        humidity: humidity,
        temp: temp_f,
        dew_point: dew_point,
        utc_time: utc_time,
        timezone: timezone}),
      qos: 0)

    Logger.info("#{utc_time} -- humidity: #{humidity}%, temp: #{temp_f}°F, dew_point #{dew_point}°F")
    schedule_collection()

    {:noreply, ref}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection() do
    Process.send_after(self(), :collect, 60_000)
  end
end
