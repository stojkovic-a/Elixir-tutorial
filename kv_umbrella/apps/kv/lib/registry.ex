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

  @doc """
  Returns the ets table identifier
  """
  def names_table() do
    GenServer.call(KV.Registry, {:ets_id})
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
    # load_saved_buckets(names, refs)
    # {:ok, {names, refs}}
    {:ok,load_saved_buckets(names,refs)}
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
  def handle_call({:ets_id}, _from, {names, refs}) do
    {:reply, names, {names, refs}}
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

  defp load_saved_buckets(names, refs) do
    if File.exists?(Application.fetch_env!(:kv, :save_dir)) do
      File.ls!(Application.fetch_env!(:kv, :save_dir))
      |> Enum.reduce(refs,fn file, acc_refs ->
        name = Path.rootname(file, ".json")

        if KV.Router.this_node?(name) do
          {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
          ref = Process.monitor(pid)
          # refs = Map.put(refs, ref, name)
          :ets.insert(names, {name, pid})

          state =File.read!(Path.join(Application.fetch_env!(:kv, :save_dir), file)) |> Jason.decode!()

          Enum.each(state, fn s ->
            KV.Bucket.put(pid,elem(s,0),elem(s,1))
            # IO.inspect(elem(s,0))
          end)

          acc_refs=Map.put(refs,ref,name)
          acc_refs
        else
          acc_refs
        end
      end)
      {names,refs}
    else
      {names,refs}
    end
  end
end
