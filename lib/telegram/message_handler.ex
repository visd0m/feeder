defmodule FeederBot.Telegram.MessageHandler do
  require Amnesia.Helper
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
      true ->
        persist_subscription(command, url)
        send_message({
          command["message"]["from"]["id"],
          "subscription confirmed to '#{url}' ✌️"
        })
      false ->
        send_message({
          command["message"]["from"]["id"],
          "😱 invalid url provided, '#{url}'"
        })
    end
  end

  defp exec_command({"/unsubscribe " <> _, _}) do
  end

  defp exec_command(_) do
  end

  defp persist_subscription(command, url) do
    exec_operation(fn ->
      %Subscription{
        user_id: command["message"]["from"]["id"],
        chat_id: command["message"]["chat"]["id"],
        url: url,
        enabled: true,
        last_update: nil
      } |> Subscription.write
    end)
  end
end
