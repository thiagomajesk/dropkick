defmodule Dropkick.Security do
  @moduledoc false
  alias Dropkick.Attachment

  @key_base Application.compile_env!(:dropkick, :secret_key_base)

  def sign(%Attachment{key: key}) do
    Plug.Crypto.encrypt(@key_base, to_string(__MODULE__), key, max_age: 3600)
  end

  def check(token) when is_binary(token) do
    Plug.Crypto.decrypt(@key_base, to_string(__MODULE__), token)
  end
end
