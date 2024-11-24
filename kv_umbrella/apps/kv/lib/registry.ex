defmodule KV.Registry do
  use GenServer

  @doc """
      Starts the registry.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
      Looks up the bucket pid for 'name' stored in 'server'.

      Returns '{:ok, pid}' if the bucket exists, ':error' otherwise/
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end

    # GenServer.call(server, {:lookup, name})
  end

  # @doc """
  #     Ensures there is a bucket associated with the given 'name' in 'server'.
  # """
  # def create(server, name) do
  #   GenServer.cast(server, {:create, name})
  # end

  @doc """
      Ensures there is a bucket associated with the given 'name' in 'server'.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @impl true
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  # @impl true
  # def handle_call({:lookup, name}, _from, state) do
  #   {names, _} = state
  #   {:reply, Map.fetch(names, name), state}
  # end
  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    case lookup(names, name) do
      {:ok, _pid} ->
        {:noreply, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:noreply, {names, refs}}
    end

    # if Map.has_key?(names, name) do
    #   {:noreply, {names, refs}}
    # else
    #   {:ok, pid}=DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
    #   # {:ok, bucket} = KV.Bucket.start_link([])
    #   ref = Process.monitor(pid)
    #   refs = Map.put(refs, ref, name)
    #   names = Map.put(names, name, pid)
    #   {:noreply, {names, refs}}
    # end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    # names = Map.delete(names, name)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
