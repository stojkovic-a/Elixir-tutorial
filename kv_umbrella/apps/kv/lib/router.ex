defmodule KV.Router do
  @doc """
  Dispatch the given 'mod', 'fub', 'args' request
  to the appropriate node based on the 'bucket'.
  """
  def this_node?(bucket) do
    first = :binary.first(bucket)

    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    if elem(entry, 1) == node() do
      true
    else
      false
    end
  end

  def route(bucket, mod, fun, args) do
    first = :binary.first(bucket)

    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
  end

  @doc """
  The routing table
  """
  def table do
    Application.fetch_env!(:kv, :routing_table)
    # [{?a..?m, :"foo@diffine-pc"}, {?n..?z, :"bar@diffine-pc"}]
  end
end
