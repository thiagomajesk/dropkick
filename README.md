# Dropkick

Dropkick is a highly experimental library that provides easy to use uploads for the Elixir/ Phoenix ecosystem.  
This is a opinionated library focused on developer ergonomics that you can use to provide file uploads in any Phoenix project.

## Installation

```elixir
def deps do
  [
    {:dropkick, ">= 0.0.0"}
  ]
end
```

## Usage

### Setup

- Add a map column to your database table: `add(:avatar, :map)` 
- Add a `Dropkick.File` field to your ecto schema: `field(:avatar, Dropkick.File)`

### Configuration

Add the following configuration to your `config.exs`:

```elixir
config :dropkick,
  repo: MyAppRepo,
  storage: Dropkick.Storage.Disk,
  folder: "uploads"
```

### Uploader

Define an uplodader for your application:

```elixir
defmodule MyApp.Uploader do
  use Dropkick.Uploader

  # Defines where to store the user avatar through pattern matching
  def storage_prefix({user, :avatar}), do: "avatars/#{user.id}"

  # You can add callbacks to modify or cleanup files after operations
  # def on_before_store(_scope, file), do: {:ok, file}
  # def on_before_delete(_scope, file), do: {:ok, file}
end 
```

### Save the files

```elixir
import Dropkick.Context

def create_user(user, attrs) do
  user
  |> User.changeset(attrs)
  |> insert_with_files(MyApp.Uploader)
end

def update_user(user, attrs) do
  user
  |> User.changeset(attrs)
  |> update_with_files(MyApp.Uploader)
end
```

## Missing bits

- Add more file transformations
- Support other types of storages (S3, Azure, etc)
- Add strategy to allow cleaning up old files after update
- Improve documentation for modules and functions