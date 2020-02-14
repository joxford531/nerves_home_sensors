defmodule WeatherSensor.BmpSensor do
  ## Logic for BMP085 & BMP180 sensors

  alias Circuits.I2C
  use Bitwise

  @sealevel_pa 101325
  @oss_mode 3

  def start() do
    {:ok, ref} = I2C.open("i2c-1")
    ref
  end

  def raw_temp(ref) do
    I2C.write(ref, Application.get_env(:weather_sensor, :bmp180_address), <<0xf4, 0x2e>>)
    Process.sleep(5)
    {:ok, <<value::big-unsigned-size(16)>>} = I2C.write_read(ref, Application.get_env(:weather_sensor, :bmp180_address), <<0xf6>>, 2)
    value
  end

  def raw_pressure(ref) do
    I2C.write(ref, Application.get_env(:weather_sensor, :bmp180_address), <<0xf4, (0x34 + (@oss_mode <<< 6))>>)
    Process.sleep(26)
    {:ok, <<msb::big-unsigned-size(8)>>} = I2C.write_read(ref, Application.get_env(:weather_sensor, :bmp180_address), <<0xf6>>, 1)
    {:ok, <<lsb::big-unsigned-size(8)>>} = I2C.write_read(ref, Application.get_env(:weather_sensor, :bmp180_address), <<(0xf6 + 1)>>, 1)
    {:ok, <<xlsb::big-unsigned-size(8)>>} = I2C.write_read(ref, Application.get_env(:weather_sensor, :bmp180_address), <<(0xf6 + 2)>>, 1)
    raw = ((msb <<< 16) + (lsb <<< 8) + xlsb) >>> (8 - @oss_mode)
    raw
  end

  def calibration(ref) do
    {:ok, <<dig_AC1::big-signed-size(16),
      dig_AC2::big-signed-size(16),
      dig_AC3::big-signed-size(16),
      dig_AC4::big-unsigned-size(16),
      dig_AC5::big-unsigned-size(16),
      dig_AC6::big-unsigned-size(16),
      dig_B1::big-signed-size(16),
      dig_B2::big-signed-size(16),
      dig_MB::big-signed-size(16),
      dig_MC::big-signed-size(16),
      dig_MD::big-signed-size(16)>>} =

    I2C.write_read(
      ref,
      Application.get_env(:weather_sensor, :bmp180_address), <<0xAA>>, 22
    )

    %{dig_AC1: dig_AC1,
      dig_AC2: dig_AC2,
      dig_AC3: dig_AC3,
      dig_AC4: dig_AC4,
      dig_AC5: dig_AC5,
      dig_AC6: dig_AC6,
      dig_B1: dig_B1,
      dig_B2: dig_B2,
      dig_MB: dig_MB,
      dig_MC: dig_MC,
      dig_MD: dig_MD}
  end

  def read_temp(ref) do
    cal = calibration(ref)
    ut = raw_temp(ref)

    x1 = ((ut - cal.dig_AC6) * cal.dig_AC5) >>> 15
    x2 = (cal.dig_MC <<< 11) / (x1 + cal.dig_MD)
    b5 = Kernel.round(x1 + x2)
    temp = ((b5 + 8) >>> 4) / 10.0
    temp
  end

  def read_temp_f(ref) do
    read_temp(ref)
    |> celsius_to_fahrenheit()
  end

  def read_pressure(ref) do
    cal = calibration(ref)
    ut = raw_temp(ref)
    up = raw_pressure(ref)

    # calculate real temp first
    x1 = ((ut - cal.dig_AC6) * cal.dig_AC5) >>> 15
    x2 = (cal.dig_MC <<< 11) / (x1 + cal.dig_MD)
    b5 = Kernel.round(x1 + x2)
    b6 = b5 - 4000

    x1 = (cal.dig_B2 * (b6 * b6) >>> 12) >>> 11
    x2 = (cal.dig_AC2 * b6) >>> 11
    x3 = x1 + x2
    b3 = (((cal.dig_AC1 * 4 + x3) <<< @oss_mode) + 2) / 4

    x1 = (cal.dig_AC3 * b6) >>> 13
    x2 = (cal.dig_B1 * ((b6 * b6) >>> 12)) >>> 16
    x3 = ((x1 + x2) + 2) >>> 2
    b4 = (cal.dig_AC4 * (x3 + 32768)) >>> 15
    b7 = (up - b3) * (50000 >>> @oss_mode)

    p =
      cond do
        b7 < 0x80000000 -> (b7 * 2) / b4
        true -> (b7 / b4) * 2
      end

    x1 = (Kernel.round(p) >>> 8) * (Kernel.round(p) >>> 8)
    x1 = (x1 * 3038) >>> 16
    x2 = Kernel.round((-7357 * p)) >>> 16

    p = p + ((x1 + x2 + 3791) >>> 4)

    p
  end

  def read_pressure_us(ref) do
    pressure = read_pressure(ref)
    pascals_to_inHg(pressure)
  end

  def read_altitude(ref) do
    pressure = read_pressure(ref)
    altitude = 44330.0 * (1.0 - :math.pow(pressure / @sealevel_pa, 0.1903))
    altitude
  end

  def estimate_altitude(ref) do
    Enum.reduce(0..5, fn _, acc -> __MODULE__.read_altitude(ref) + acc end) / 5
  end

  @doc """
  Read the temperature and pressure from the BMP180.
  Return Celsius and Pascals
  """
  def temp_and_pressure(ref) do
    temp = read_temp(ref)
    pressure = read_pressure(ref)

    {temp, pressure}
  end

  @doc """
  Read the temperature and pressure and return in US units.
  I.e., Fahrenheit and inches of mercury
  """
  def temp_and_pressure_us(ref) do
    {t, p} = temp_and_pressure(ref)
    {celsius_to_fahrenheit(t),
     pascals_to_inHg(p)}
  end

  def measure_all_us(ref) do
    {t, p} = temp_and_pressure_us(ref)
    altitude = estimate_altitude(ref)

    %{temperature: t,
      pressure: p,
      altitude: meters_to_feet(altitude),
      units: :us}
  end

  def calculate_dewpoint(humidity, temp) do
    k = :math.log(humidity/100) + (17.62 * temp) / (243.12 + temp)
    243.12 * k / (17.62 - k)
  end

  defp celsius_to_fahrenheit(t) do
    32 + 1.8 * t
  end

  defp pascals_to_inHg(p) do
    p * 0.00029529983071445
  end

  defp meters_to_feet(m), do: 3.2808399 *m

end
