defmodule WeatherSensor.DhtServer do
  use GenServer
  require Logger

  def start_link(_) do
    Logger.info("Starting DHT Reader")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_collection()
    {:ok, %{humidity: nil, temp: nil}}
  end

  @impl true
  def handle_info(:collect, _old_state) do
    {:ok, humidity, temp} = NervesDHT.read(:am2302, Application.get_env(:weather_sensor, :dht_pin))
    Tortoise.publish("weather_sensor", "front/temp_humidity", Jason.encode!(%{humidity: humidity, temp: temp}), qos: 0)
    Logger.info("humidity: #{humidity}, temp: #{temp}")
    schedule_collection()

    {:noreply, %{humidity: humidity, temp: temp}}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection() do
    Process.send_after(self(), :collect, 5_000)
  end
end
