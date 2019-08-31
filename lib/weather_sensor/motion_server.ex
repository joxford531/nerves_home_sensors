defmodule WeatherSensor.MotionServer do
  use GenServer
  alias Circuits.GPIO
  require Logger

  def start_link(_) do
    IO.puts("Starting MotionServer")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, trig} = GPIO.open(Application.get_env(:weather_sensor, :hcsr04_trig_pin), :output)
    {:ok, echo} = GPIO.open(Application.get_env(:weather_sensor, :hcsr04_echo_pin), :input)
    schedule_collection()
    {:ok, %{trig: trig, echo: echo}}
  end

  @impl true
  def handle_info(:collect, %{trig: trig, echo: echo}) do
    distance = get_distance(trig, echo)

    cond do
      distance < 200 ->
        Tortoise.publish("weather_sensor", "front/motion", "#{distance}", qos: 0)
        Logger.info("Distance: #{distance}cm")
        schedule_collection(10_000)
      true ->
        Logger.info("Distance: #{distance}cm")
        schedule_collection()
    end

    {:noreply, %{trig: trig, echo: echo}}
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

  defp get_distance(trig, echo) do
    GPIO.write(trig, 0)
    Process.sleep(2)
    GPIO.write(trig, 1)
    Process.sleep(1)
    GPIO.set_interrupts(echo, :both)

    time_start =
      receive do
        {:circuits_gpio, _pin, time_start, 1} -> time_start
      after
        5_000 -> raise "time_start not receieved for HC-SR04 sensor"
      end

    time_end =
      receive do
        {:circuits_gpio, _pin, time_end, 0} -> time_end
      after
        5_000 -> raise "time_stop not receieved for HC-SR04 sensor"
      end

    diff_in_s = (time_end - time_start) / 1.0e9
    dist_in_cm = Float.round(diff_in_s * 17150.0, 2)

    dist_in_cm
  end
end
