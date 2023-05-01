defmodule AttachableTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc
  use Dropkick.FileCase

  describe "attachable protocol" do
    test "works with binary", %{path: path} do
      assert Dropkick.Attachable.name("foo") == "foo"
      assert Dropkick.Attachable.name("foo/bar") == "bar"
      assert Dropkick.Attachable.name("foo/bar.jpg") == "bar.jpg"
      assert Dropkick.Attachable.name(path) == Path.basename(path)

      assert {:error, "Could not read path: enoent"} = Dropkick.Attachable.content("foo")
      assert {:error, "Could not read path: enoent"} = Dropkick.Attachable.content("foo/bar")
      assert {:error, "Could not read path: enoent"} = Dropkick.Attachable.content("foo/bar.jpg")
      assert {:ok, "Hello World"} = Dropkick.Attachable.content(path)
    end

    @tag :nofile
    test "works with binary that looks like a URL" do
      ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
      uri = "https://octodex.github.com/images/dojocat.jpg"

      use_cassette "github_octodex_dojocat" do
        assert "dojocat.jpg" = Dropkick.Attachable.name(uri)
        # Asserts that we are actually dealing with the correct file format (JPG)
        assert {:ok, <<0xFF, 0xD8, _rest::binary>>} = Dropkick.Attachable.content(uri)
      end
    end

    test "works with upload struct", %{path: path} do
      upload = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert Dropkick.Attachable.name(upload) == Path.basename(path)
      assert {:ok, "Hello World"} = Dropkick.Attachable.content(upload)
    end

    @tag :nofile
    test "works with URI" do
      ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
      uri = URI.new!("https://octodex.github.com/images/dojocat.jpg")

      :inets.start()

      use_cassette "github_octodex_dojocat" do
        assert "dojocat.jpg" = Dropkick.Attachable.name(uri)
        # Ensure we are dealing with a JPG
        assert {:ok, <<0xFF, 0xD8, _rest::binary>>} = Dropkick.Attachable.content(uri)
      end
    end
  end
end
