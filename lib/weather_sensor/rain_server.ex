defmodule WeatherSensor.RainServer do
  use GenServer
  alias Circuits.GPIO
  require Logger

  def start_link(_) do
    IO.puts("Starting RainServer")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, gpio} = GPIO.open(Application.get_env(:weather_sensor, :rain_pin), :input)
    GPIO.set_pull_mode(gpio, :pullup)
    schedule_collection()
    {:ok, {gpio, 0}}
  end

  def get_rainfall_amt() do
    GenServer.call(__MODULE__, :get_and_reset)
  end

  def get_rainfall_amt_in() do
    GenServer.call(__MODULE__, :get_inches_and_reset)
  end

  @impl true
  def handle_call(:get_and_reset, _from, {gpio, amount}) do
    {:reply, amount, {gpio, 0}} # return amount in mm and reset to 0
  end

  @impl true
  def handle_call(:get_inches_and_reset, _from, {gpio, amount}) do
    {:reply, amount * 0.0393701, {gpio, 0}} # return amount in inches and reset to 0
  end

  @impl true
  def handle_info(:collect, {gpio, total}) do
    rainfall_amt = detect_rainfall(gpio)

    schedule_collection()

    {:noreply, {gpio, rainfall_amt + total}}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.puts("Unknown message")
    Kernel.inspect(unknown_message)
    {:noreply, state}
  end

  defp schedule_collection() do
    Process.send_after(self(), :collect, 300)
  end

  defp detect_rainfall(gpio) do
    GPIO.set_interrupts(gpio, :falling)

    amount =
      receive do
        {:circuits_gpio, _pin, _time, _} -> 0.2794 # amount in mm that will trigger interrupt
      after
        2_000 -> 0
      end

    amount
  end

end
