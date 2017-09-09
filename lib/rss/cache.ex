defmodule FeederBot.Rss.Cache do
    use GenServer

    @ttl 60

    def start_link() do
      GenServer.start_link(__MODULE__, __MODULE__, name: __MODULE__)
    end

    def get(url) do
      GenServer.call(__MODULE__, {:get, url})
    end

    def put({url, feed}) do
      GenServer.cast(__MODULE__, {:put, {url, feed}})
    end

    # ======== callbacks
    def init(opts) do
      feeds = :ets.new(opts, [:named_table, read_concurrency: true])
      {:ok, feeds}
    end

    def handle_call({:get, url}, _from, feeds) do
      result = with {:ok, feed} <- lookup(feeds, url)
      do
        feed
      else
        :error -> []
      end
      {:reply, result, feeds}
    end

    def handle_cast({:put, {url, feed}}, feeds) do
      expiration = :os.system_time(:seconds) + @ttl
      :ets.insert(feeds, {url, {feed, expiration}})
      {:noreply, feeds}
    end

    defp lookup(table, key) do
      case :ets.lookup(table, key) do
        [{^key, entry}] -> {:ok, check_ttl(entry)}
        [] -> :error
      end
    end

    defp check_ttl({feed, expiration}) do
      case expiration > :os.system_time(:seconds) do
        true -> feed
        false -> []
      end
    end
end
