import Config

config :dropkick,
  repo: TestRepo,
  storage: Dropkick.Storage.Disk,
  folder: "uploads"
