defmodule FeederBot.Rss.Fetcher do
  use GenServer
  use FeederBot.Persistence.Database
  require Logger
  import FeederBot.Persistence.DatabaseHandler
  import FeederBot.Telegram

  def load_subscriptions do
    subscriptions = exec_operation(fn ->
      Subscription.where(:id > 0)
        |> Amnesia.Selection.values
    end)
    Logger.info("actual subscriptions: #{inspect(subscriptions)}")

    feeds_by_users = subscriptions
      |> Enum.map(fn (subscription) ->
        {subscription, extract_feed(subscription)}
      end)

    feeds_by_users
      |> Enum.each(fn({subscription, feed}) ->
        send_updates({subscription, feed})
        update_subscription({subscription, feed})
      end)
  end

  defp extract_feed(subscription) do
    filtering_date = case subscription.last_update do
      nil -> -1
      a_date -> a_date
    end
    ElixirFeedParser.parse(HTTPoison.get!(subscription.url).body).entries
      |> Enum.filter(fn(feed) ->
         Logger.info("feed_entry: #{inspect(feed)}")
         Logger.info("filtering_date: #{inspect(filtering_date)}")
         feed_date = extract_timestamp(feed.updated)
         Logger.info("feed_date: #{inspect(feed_date)}")

         filtering_date < feed_date
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

  def check_subscription(url) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        try do
          ElixirFeedParser.parse(response.body)
          true
        catch
          _ -> false
        end
      {:error, _} ->
        false
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
