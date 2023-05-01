import Config

config :dropkick,
  storage: Dropkick.Storage.Memory,
  secret_key_base: Base.encode64(String.duplicate("x", 12))

import_config "#{Mix.env()}.exs"
