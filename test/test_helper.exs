ExUnit.start()

defmodule TestRepo do
  use Ecto.Repo, otp_app: :dropkick, adapter: Ecto.Adapters.Postgres
  use Dropkick.Ecto.Repo
end

Application.put_env(:dropkick, TestRepo,
  url: "ecto://postgres:postgres@localhost/dropkick",
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
)

defmodule TestUser do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:avatar, Dropkick.Ecto.File)
  end
end

defmodule TestMigrationSetup do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:avatar, :map)
    end
  end
end

_ = Ecto.Adapters.Postgres.storage_down(TestRepo.config())

:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()

:ok = Ecto.Migrator.up(TestRepo, 0, TestMigrationSetup, log: false)

Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
