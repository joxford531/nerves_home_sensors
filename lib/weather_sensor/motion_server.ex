defmodule WeatherSensor.MotionServer do
  alias WeatherSensor.MotionReader
  use GenServer

  def start_link(_) do
    IO.puts("Starting BmpServer")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    ref = MotionReader.start()
    start_sensor_collection(ref)
    {:ok, ref}
  end

  defp start_sensor_collection(ref) do

  end
end
