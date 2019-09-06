defmodule WeatherSensor.WeatherServer do
  use GenServer
  require Logger
  alias WeatherSensor.{Sht31Sensor, BmpSensor}

  def start_link(_) do
    Logger.info("Starting Weather Server")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    sht_ref = Sht31Sensor.start()
    bmp_ref = BmpSensor.start()
    schedule_collection()
    {:ok, %{sht_ref: sht_ref, bmp_ref: bmp_ref}}
  end

  @impl true
  def handle_info(:collect, %{sht_ref: sht_ref, bmp_ref: bmp_ref}) do
    utc_time = DateTime.utc_now()
    timezone = Application.get_env(:weather_sensor, :timezone)
    {temp_f, humidity, dew_point_f} = Sht31Sensor.read_temp_humidity_dew_point_us(sht_ref)
    pressure_inhg = BmpSensor.read_pressure_us(bmp_ref)

    humidity = Float.round(humidity, 1)

    temp_f = Float.round(temp_f, 1)

    dew_point_f = Float.round(dew_point_f, 1)

    pressure_inhg = Float.round(pressure_inhg, 2)

    Tortoise.publish("weather_sensor", "front/temp_humidity_dew_point_pressure",
      Jason.encode!(%{
        humidity: humidity,
        temp: temp_f,
        dew_point: dew_point_f,
        utc_time: utc_time,
        timezone: timezone}),
      qos: 0)

    Logger.info("#{utc_time} --
      humidity: #{humidity}%, temp: #{temp_f}°F, dew_point #{dew_point_f}°F, pressure: #{pressure_inhg} inHg")

    schedule_collection()

    {:noreply,  %{sht_ref: sht_ref, bmp_ref: bmp_ref}}
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
