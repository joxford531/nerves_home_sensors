defmodule WeatherSensor.MotionServer do
  alias WeatherSensor.Hcsr04Server
  use GenServer
  require Logger

  def start_link(_) do
    IO.puts("Starting MotionServer")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, sensor} = Hcsr04Server.start_link(
      {
        Application.get_env(:weather_sensor, :hcsr04_echo_pin),
        Application.get_env(:weather_sensor, :hcsr04_trig_pin)
      }
    )
    schedule_collection()
    {:ok, sensor}
  end

  @impl true
  def handle_info(:collect, sensor) do
    :ok = Hcsr04Server.update(sensor)
    Process.sleep(100)
    {:ok, distance} = Hcsr04Server.info(sensor)

    cond do
      distance < 140 ->
        Tortoise.publish("weather_sensor", "front/motion", "#{distance}", qos: 0)
        Logger.info("Distance: #{distance}cm, Motion Detected!")
        schedule_collection(10_000)
      true -> schedule_collection()
    end

    {:noreply, sensor}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection() do
    Process.send_after(self(), :collect, 1000)
  end

  defp schedule_collection(delay) when is_number(delay) do
    Process.send_after(self(), :collect, delay)
  end
end
