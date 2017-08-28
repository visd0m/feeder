defmodule FeederBot.Telegram.MessageHandler do
  require Logger
  use FeederBot.Persistence.Database
  import FeederBot.Persistence.DatabaseHandler
  import FeederBot.Telegram
  import FeederBot.Rss.Fetcher

  def handle_command(command) do
    {command["message"]["text"], command}
      |> exec_command
  end

  defp exec_command({"/subscribe " <> url, command}) do
    case check_subscription(url) do
      {:ok, feed} ->
        persist_subscription(command, url, feed)
        send_message({
          command["message"]["from"]["id"],
          "subscription confirmed to '#{url}' ✌️"
        })
      {:error, _} ->
        send_message({
          command["message"]["from"]["id"],
          "😱 invalid url provided, '#{url}'"
        })
    end
  end

  defp exec_command({"/unsubscribe " <> url, command}) do
    subscriptions = exec_operation(fn() ->
      Subscription.where(user_id == command["message"]["from"]["id"] and url == "#{url}")
    end) |> Amnesia.Selection.values

    subscriptions
      |> Enum.each(fn(subscription) -> unsubscribe(subscription) end)

    send_message({
      command["message"]["from"]["id"],
      "correctly unsubscribed from, '#{url}' run away from the spam 🏃"
    })
  end

  defp exec_command({"/list", command}) do
    subscriptions = exec_operation(fn() ->
      Subscription.where(user_id == command["message"]["from"]["id"] and enabled == true)
    end)

    urls = subscriptions
      |> Amnesia.Selection.values
      |> Enum.map(fn(subscription) -> subscription.url end)
      |> Enum.join("\n")

    send_message({
      command["message"]["from"]["id"],
      "enabled subscriptions:\n#{urls}"
    })
  end

  defp exec_command({"/start" <> _, command}) do
    send_message({
      command["message"]["from"]["id"],
      "Welcome to the best feed bot ever made 👾\ntype /help to get the list of available commands"
    })
  end

  defp exec_command({"/stop" <> _, command}) do
    send_message({
      command["message"]["from"]["id"],
      "I've always hated goodbyes 😩"
    })

    subscriptions = exec_operation(fn() ->
      Subscription.where(user_id == command["message"]["from"]["id"] and enabled == true)
    end)

    subscriptions
      |> Enum.each(fn(subscription) -> unsubscribe(subscription) end)
  end

  defp exec_command({"/help" <> _, command}) do
    send_message({
      command["message"]["from"]["id"],
      "available commands:\n/subscribe <url>\n/unsubscribe <url>\n/list\n"
    })
  end

  defp exec_command({_, command}) do
    send_message({
      command["message"]["from"]["id"],
      "unknown command .."
    })
  end

  defp persist_subscription(command, url, feed) do
    last_id = case feed.entries do
      [_ | _] ->
        List.first(feed).updated
      _ ->
        -1
    end
    exec_operation(fn ->
      %Subscription{
        user_id: command["message"]["from"]["id"],
        chat_id: command["message"]["chat"]["id"],
        url: url,
        enabled: true,
        last_update: last_id
      } |> Subscription.write
    end)
  end

  defp unsubscribe(subscription) do
    exec_operation(fn ->
      %Subscription{subscription | enabled: false}
        |> Subscription.write
    end)
  end
end
