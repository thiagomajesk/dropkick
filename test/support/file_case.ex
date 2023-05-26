defmodule Dropkick.FileCase do
  @moduledoc """
  Defines a template that can be used to automatically create and dispose files in the disk.
  Each test case gets a unique id that represents the folder where the files used will be stored.
  Then, for each test in the case, it's created a file with the contents "Hello World".
  If you don't want that a file is automatically created, you can pass `@tag :nofile`.
  It's also possible to define the name of the file passing `@tag filename: "customname.jpg"`.
  Alternatively, you can pass `@tag copy: "/fixtures/images` to the test to copy a given file.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Set module attribute to retrieve value from helpers
      # and proxy value to tags so we can properly cleanup after all tests
      @moduletag case_id: System.unique_integer([:positive])
    end
  end

  setup tags do
    folder = "dropkick-test-case-#{Map.fetch!(tags, :case_id)}"
    tmp_dir = Path.join(System.tmp_dir!(), folder)

    filename =
      Map.get_lazy(tags, :filename, fn ->
        file_id = System.unique_integer()
        Base.encode32(to_string(file_id), padding: false) <> ".jpg"
      end)

    tags =
      if tags[:nofile] do
        tags
      else
        path = Path.join(tmp_dir, filename)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, "Hello World")
        on_exit(fn -> File.rm_rf!(tmp_dir) end)
        Map.put(tags, :path, path)
      end

    tags =
      if path = tags[:copy] do
        cp_path = Path.join(tmp_dir, Path.basename(path))
        File.cp!(path, cp_path)
        on_exit(fn -> File.rm_rf!(tmp_dir) end)
        Map.put(tags, :path, cp_path)
      else
        tags
      end

    Map.merge(tags, %{dir: tmp_dir})
  end
end
