# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

import_config "private.exs"

config :weather_sensor, target: Mix.target()

config :tzdata, :autoupdate, :disabled

config :weather_sensor,
  dht_pin: 4,
  rain_pin: 17,
  sht31_address: 0x44,
  bmp180_address: 0x77,
  timezone: "America/New_York",
  city_id: 4192289 # openweather API city_id

config :power_control,
  cpu_governor: :powersave,
  disable_hdmi: true,
  disable_leds: true

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget, :power_control],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

if Mix.target() != :host do
  import_config "target.exs"
end
