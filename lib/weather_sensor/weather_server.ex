defmodule WeatherSensor.WeatherServer do
  use GenServer
  require Logger
  alias WeatherSensor.BmpSensor

  def start_link(_) do
    Logger.info("Starting DHT Reader")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    ref = BmpSensor.start()
    schedule_collection()
    {:ok, ref}
  end

  @impl true
  def handle_info(:collect, ref) do
    utc_time = DateTime.utc_now()
    timezone = Application.get_env(:weather_sensor, :timezone)
    {:ok, humidity, temp} = NervesDHT.read(:am2302, Application.get_env(:weather_sensor, :dht_pin))

    pressure =
      BmpSensor.read_pressure(ref)
      |> BmpSensor.pascals_to_inHg()
      |> Float.round(2)

    humidity = Float.round(humidity, 1)

    temp_f =
      BmpSensor.celsius_to_fahrenheit(temp)
      |> Float.round(1)

    Tortoise.publish("weather_sensor", "front/temp_humidity_pressure",
      Jason.encode!(%{humidity: humidity, temp: temp_f, pressure: pressure, utc_time: utc_time, timezone: timezone}), qos: 0)

    Logger.info("#{utc_time} -- humidity: #{humidity}%, temp: #{temp_f}°F, pressure: #{pressure} inHg")
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
