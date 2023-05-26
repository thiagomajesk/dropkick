import Config

config :dropkick, storage: Dropkick.Storage.Memory

import_config "#{Mix.env()}.exs"
