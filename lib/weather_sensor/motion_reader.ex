defmodule WeatherSensor.MotionReader do
  alias Circuits.GPIO

  def start() do
    {:ok, gpio} = GPIO.open(Application.get_env(:weather_sensor, :sr501_pin), :input)
    Process.sleep(2_000)
    {:ok, gpio}
  end

  def read(gpio) do
    GPIO.read(gpio)
  end
end
