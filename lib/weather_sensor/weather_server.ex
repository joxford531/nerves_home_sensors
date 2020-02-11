defmodule WeatherSensor.WeatherServer do
  use GenServer
  use Timex
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

    GenServer.start_link(WeatherSensor.RainServer, nil, name: WeatherSensor.RainServer)

    Process.send_after(self(), :collect, 1000)
    {:ok, %{sht_ref: sht_ref, bmp_ref: bmp_ref}}
  end

  @impl true
  def handle_info(:collect, %{sht_ref: sht_ref, bmp_ref: bmp_ref}) do
    utc_time = DateTime.utc_now()
    timezone = Application.get_env(:weather_sensor, :timezone)
    {temp_sht_f, humidity, dew_point_f} = Sht31Sensor.read_temp_humidity_dew_point_us(sht_ref)
    {temp_bmp_f, pressure_inhg} = BmpSensor.temp_and_pressure_us(bmp_ref)
    rainfall = WeatherSensor.RainServer.get_rainfall_amt_in()
    city_id = Application.get_env(:weather_sensor, :city_id)

    humidity = Float.round(humidity, 1)
    temp_sht_f = Float.round(temp_sht_f, 1)
    temp_bmp_f = Float.round(temp_bmp_f, 1)
    dew_point_f = Float.round(dew_point_f, 1)

    pressure_inhg = Float.round(pressure_inhg, 2)

    Tortoise.publish("weather_sensor", "front/temp_humidity_dew_point_pressure",
      Jason.encode!(
        %{
          :humidity => humidity,
          :temp_sht => temp_sht_f,
          :temp_bmp => temp_bmp_f,
          :dew_point => dew_point_f,
          :pressure => pressure_inhg,
          :rainfall => rainfall,
          :time => utc_time,
          :timezone => timezone,
          :city_id => city_id
        }),
      qos: 0)

    Logger.info("""
      #{utc_time} -- humidity: #{humidity}%, temp_sht_f: #{temp_sht_f}°F, temp_bmp_f: #{temp_bmp_f}°F,
      dew_point #{dew_point_f}°F, pressure: #{pressure_inhg} inHg, rainfall: #{rainfall} in")
      """
    )

    schedule_collection(60_000 - Timex.diff(DateTime.utc_now(), utc_time, :milliseconds)) # try to send only once per minute

    {:noreply,  %{sht_ref: sht_ref, bmp_ref: bmp_ref}}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection(delay_in_ms) do
    Process.send_after(self(), :collect, delay_in_ms)
  end
end
