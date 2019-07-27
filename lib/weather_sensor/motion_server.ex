defmodule WeatherSensor.MotionServer do
  alias WeatherSensor.MotionReader
  use GenServer
  require Logger

  def start_link(_) do
    IO.puts("Starting BmpServer")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, ref} = MotionReader.start()
    schedule_collection()
    {:ok, ref}
  end

  @impl true
  def handle_info(:collect, ref) do
    case MotionReader.read(ref) do
      1 ->
        Tortoise.publish("weather_sensor", "front/motion", "motion", qos: 0)
        Logger.info("Motion Detected!")
        schedule_collection(10_000)
      _ -> schedule_collection()
    end

    {:noreply, ref}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection() do
    Process.send_after(self(), :collect, 500)
  end

  defp schedule_collection(delay) when is_number(delay) do
    Process.send_after(self(), :collect, delay)
  end
end
