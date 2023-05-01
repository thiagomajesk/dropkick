defmodule SecurityTest do
  use ExUnit.Case
  use Dropkick.FileCase

  alias Dropkick.Attachment

  test "sign/check" do
    atch = %Attachment{key: "/", filename: "", content_type: "", storage: Dropkick.Storage.Memory}
    token = Dropkick.Security.sign(atch)
    assert {:ok, "/"} = Dropkick.Security.check(token)
  end
end
