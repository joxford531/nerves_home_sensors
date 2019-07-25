defmodule WeatherSensor.MotionReader do
  alias Circuits.GPIO

  def start() do
    {:ok, gpio} = GPIO.open(20, :input)
    Process.sleep(2_000)
    {:ok, gpio}
  end

  def read(gpio) do
    GPIO.read(gpio)
  end
end
