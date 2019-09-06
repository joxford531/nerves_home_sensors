# WeatherSensor

## Project

Generated skeleton with [nerves_init_gadget](https://github.com/nerves-project/nerves_init_gadget) and added basic modules related to
the BMP180, SHT3x, and HC-SR04 sensors under a supervision tree. The weather sensors are polled every minute and their results pushed to my MQTT broker. The weather sensors are controlled using [`Circuits.I2C`](https://github.com/elixir-circuits/circuits_i2c)

The motion sensor is polled every 500ms unless something crosses roughly 200cm in front of it, this will cause a result to be pushed 
to my MQTT broker and then delayed an additional 10 seconds. This is using [`Circuits.GPIO.set_interrupts`](https://github.com/elixir-circuits/circuits_gpio) to catch the rising and falling edge of the echo and therefore it's accuracy is probably limited to a
couple of cm, enough to catch something passing in front of it.

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
