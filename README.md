# Dropkick

Dropkick is a highly experimental library that provides easy to use uploads for the Elixir/ Phoenix ecosystem.
This is a opinionated library focused on developer ergonomics that you can use to provide file uploads in any Phoenix project.

Some inspiration was taken from other projects like [Capsule](https://github.com/elixir-capsule/capsule) and [Waffle](https://github.com/elixir-waffle/waffle) as well as Ruby's [Shrine](https://shrinerb.com/). 

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

- Add a map column to your database: `add(:avatar, :map)` 
- Add a field to your schema: `field(:avatar, Dropkick.Attachment)`

### Basic uploader example

You can setup a very basic uploader like this:

```elixir
defmodule FileUploader do
  use Dropkick.Uploader

  @impl true
  def validate(_attachable, %{action: :store}), do: :ok
end
```

After that, you simply cast the type like you would normally do:

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:avatar])
  |> validate_required([:avatar])
  |> prepare_changes(&store_attachments(&1, [:avatar]))
end

# You can add a little helper function to properly store the attachment 
# and process everything only when the changeset is actually valid.
defp store_attachments(changeset, fields) do
  Enum.reduce(fields, changeset, fn field, chset ->
    if attachment = Ecto.Changeset.get_change(changeset, field) do
      case FileUploader.store(attachment) do
        {:ok, atch} -> Ecto.Changeset.put_change(chset, field, atch)
        {:error, reason} -> Ecto.Changeset.add_error(chset, field, to_string(reason))
      end
    end
  end)
end
```

### Async uploader

You can also do async uploads by doing some modifications in the upload workflow. First you want to have an endpoint that saves (or caches) files when a user interacts with a file uploader on the frontend. When an upload arrives at this endpoint you want to call the function `FileUploader.cache(upload)` to save the file into a temporary folder (this folder should ideally be cleaned from time to time). 

```elixir
defmodule FileUploader do
  use Dropkick.Uploader

  # Skip validation when storing the file 
  def validate(_attachable, %{action: :store}), do: :ok

  # Only validates the file when caching, since we are doing async uploads
  def validate(%{filename: filename}, %{action: :cache}) do
    extension = Path.extname(filename)

    case Enum.member?(~w(.jpg .jpeg .gif .png), extension) do
      true -> :ok
      false -> {:error, "invalid file type"}
    end
  end

  # You can change how the files will be saved
  def storage_prefix(_attachable, scope) do
    %{year: year, month: month, day: day} = DateTime.utc_now()
    # The current action is automatically added to the scope, but you can
    # call the cache and store functions with custom scopes to customize this even further.
    "#{to_string(scope.action)}/#{year}/#{month}/#{day}"
  end
end
```

If you are using forms to submit the final file, you'll likely want to return the cached file path or an identifier to the frontend so you can retrieve the file in the next post (you can save this identifier into a hidden field for instance). And then, after you finish doing your schema validations you can simply call `FileUploader.store` to store the file into its final location.

> If you don't want to expose the file path, you can use the function `Dropkick.Security.sign(attachment)` to generate a token that you can send to clients. This might be desirable if you are uploading files to disk as it prevents a malicius user from tampering with the final file location.

## Missing bits

- Implement more image transformations
- Add video transformations
- Add support to S3 storage
