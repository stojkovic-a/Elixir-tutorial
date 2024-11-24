defmodule KV.Saver do
  use GenServer

  @doc """
  Starts the bucket saver process.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    File.mkdir_p!(Application.fetch_env!(:kv, :save_dir))
    schedule_save()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:save_buckets, state) do
    save_all_buckets()
    schedule_save()
    {:noreply, state}
  end

  defp schedule_save do
    Process.send_after(self(), :save_buckets, Application.fetch_env!(:kv, :save_time))
  end

  defp save_all_buckets do
    Enum.each(:ets.tab2list(KV.Registry.names_table()), fn {name, pid} ->
      if Process.alive?(pid) do
        state = Agent.get(pid, & &1)

        File.write!(
          Path.join(Application.fetch_env!(:kv, :save_dir), "#{name}.json"),
          Jason.encode!(state)
        )
      end
    end)
  end
end
