defmodule FeederBot.Rss.Fetcher do
  use GenServer
  use FeederBot.Persistence.Database
  require Logger
  import FeederBot.Persistence.DatabaseHandler
  import FeederBot.Telegram

  # public
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch_subscription(subscription) do
    GenServer.cast(__MODULE__, {:fetch, subscription})
  end

  def load_subscriptions do
    subscriptions = exec_operation(fn ->
      Subscription.where(enabled == true)
        |> Amnesia.Selection.values
    end)

    subscriptions
      |> Enum.each(fn(subscription) -> fetch_subscription(subscription) end)
  end

  def check_subscription(url) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        try do
          {:ok, ElixirFeedParser.parse(response.body)}
        catch
          _ ->
            {:error, "invalid url"}
        end
      {:error, _} ->
        {:error, "invalid url"}
    end
  end

  # callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:fetch, subscription}, _) do
    feed = extract_feed(subscription)
    send_updates({subscription, feed})
    update_subscription({subscription, feed})

    {:noreply, nil}
  end

  # private
  defp extract_feed(subscription) do
    ElixirFeedParser.parse(HTTPoison.get!(subscription.url).body).entries
      |> Enum.filter(fn(feed) ->
         feed_date = extract_timestamp(feed.updated)
         subscription.last_update < feed_date
      end)
  end

  defp extract_timestamp(date) do
    case date do
      nil ->
        -1
      _ ->
        {:ok, date_time} = date
          |> Timex.parse("{RFC1123}")
        DateTime.to_unix(date_time)
    end
  end

  defp send_updates({subscription, feed_entries}) do
    feed_entries
      |> Enum.each(fn(entry) -> send_message({subscription.user_id, entry.url}) end)
  end

  defp update_subscription({subscription, feed_entries}) do
    case feed_entries do
      [_ | _] ->
        exec_operation(fn ->
          %Subscription{subscription | last_update: extract_timestamp(List.first(feed_entries).updated)}
            |> Subscription.write
        end)
        :ok
        _ -> :ok
    end
  end
end
