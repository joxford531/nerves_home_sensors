defmodule WeatherSensor.Sht31Sensor do
  alias Circuits.I2C

  def start() do
    {:ok, ref} = I2C.open("i2c-1")
    ref
  end

  def read_temp_humidity(ref) do
    I2C.write(ref, Application.get_env(:weather_sensor, :sht31_pin), <<0x2C, 0x06>>)
    Process.sleep(50)

    {:ok, <<temp0, temp1, _, humid0, humid1, _>>} = I2C.read(ref, 0x44, 6)
    temp = -45 + (175 * (temp0 * 256 + temp1)) / 65535.0
    humidity = 100 * (humid0 * 256 + humid1) / 65535.0

    {:ok, humidity, temp}
  end

  def calculate_dewpoint(humidity, temp) do
    k = :math.log(humidity/100) + (17.62 * temp) / (243.12 + temp)
    243.12 * k / (17.62 - k)
  end

  def celsius_to_fahrenheit(t) do
    32 + 1.8 * t
  end

end

