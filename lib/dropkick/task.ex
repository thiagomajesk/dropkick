defmodule Dropkick.Task do
  @doc """
  Pipes the `value` to the given `fun` and returns the `value` itself.
  The function runs asynchronously in a unliked process for safe side effects.
  """
  def tap_async(value, fun) do
    sup = Dropkick.TransformTaskSupervisor
    Task.Supervisor.async_nolink(sup, fun.(value)) && value
  end
end
