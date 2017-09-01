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
    try do
      case HTTPoison.get(url) do
        {:ok, response} ->
          feed = response.body
            |> ElixirFeedParser.parse
            |> check_rss
        {:error, _} ->
          {:error, "invalid url"}
      end
    rescue
      e in ArgumentError ->
        {:error, "invalid url"}
    end
  end

  defp check_rss(feed) do
    case feed do
      nil ->
        {:error, "invalid url"}
      _ ->
        last_item = feed.entries
          |> List.first
        extract_timestamp(last_item.updated)
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
    case HTTPoison.get(subscription.url) do
      {:ok, response} ->
        ElixirFeedParser.parse(response.body).entries
        |> Enum.filter(fn(feed) ->
           {:ok, feed_date} = extract_timestamp(feed.updated)
           subscription.last_update < feed_date
         end)
      {:error, _} ->
        []
    end
  end

  def extract_timestamp(date) do
    case date do
      nil ->
        {:ok, -1}
      _ ->
        case date |> Timex.parse("{RFC1123}") do
          {:ok, date_time} ->
            {:ok, DateTime.to_unix(date_time)}
          {:error, _} ->
            {:error, "date can not be parsed using RFC1123"}
        end
    end
  end

  defp send_updates({subscription, feed_entries}) do
    feed_entries
      |> Enum.each(fn(entry) -> send_message({subscription.user_id, entry.url}) end)
  end

  defp update_subscription({subscription, feed_entries}) do
    case feed_entries do
      [_ | _] ->
        {:ok, feed_date} = extract_timestamp(List.first(feed_entries).updated)
        exec_operation(fn ->
          %Subscription{subscription | last_update: feed_date}
            |> Subscription.write
        end)
        :ok
        _ -> :ok
    end
  end
end
