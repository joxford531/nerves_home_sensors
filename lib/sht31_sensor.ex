defmodule WeatherSensor.Sht31Sensor do
  alias Circuits.I2C

  def start() do
    {:ok, ref} = I2C.open("i2c-1")
    ref
  end

  def read_temp_humidity_dew_point(ref) do
    I2C.write(ref, Application.get_env(:weather_sensor, :sht31_address), <<0x2C, 0x06>>)
    Process.sleep(50)

    {:ok, <<temp0, temp1, _, humid0, humid1, _>>} = I2C.read(ref, 0x44, 6)
    temp_c = -45 + (175 * (temp0 * 256 + temp1)) / 65535.0
    humidity = 100 * (humid0 * 256 + humid1) / 65535.0

    dew_point_c = calculate_dew_point(humidity, temp_c)

    {temp_c, humidity, dew_point_c}
  end

  def read_temp_humidity_dew_point_us(ref) do
    I2C.write(ref, Application.get_env(:weather_sensor, :sht31_address), <<0x2C, 0x06>>)
    Process.sleep(50)

    {:ok, <<temp0, temp1, _, humid0, humid1, _>>} = I2C.read(ref, 0x44, 6)
    temp_c = -45 + (175 * (temp0 * 256 + temp1)) / 65535.0
    humidity = 100 * (humid0 * 256 + humid1) / 65535.0

    dew_point_f =
      calculate_dew_point(humidity, temp_c)
      |> celsius_to_fahrenheit()

    temp_f = celsius_to_fahrenheit(temp_c)

    {temp_f, humidity, dew_point_f}
  end

  def calculate_dew_point(humidity, temp_c) do
    k = :math.log(humidity/100) + (17.62 * temp_c) / (243.12 + temp_c)
    243.12 * k / (17.62 - k)
  end

  defp celsius_to_fahrenheit(t) do
    32 + 1.8 * t
  end

end

