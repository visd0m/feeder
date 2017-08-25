defmodule Feeder.Telegram.MessageHandler do
  import Feeder.Telegram.Bot
  require Amnesia.Helper
  require Logger
  use Feeder.Persistence.Database
  import Feeder.Persistence.DatabaseHandler

  def handle_command(command) do
    {command["message"]["text"], command}
      |> exec_command
  end

  defp exec_command({"/subscribe " <> url, command}) do
    persist_subscription(command, url)

    send_message({
      command["message"]["from"]["id"],
      "👾 subscription confirmed to '#{url}'"
    })
  end

  defp exec_command({"/unsubscribe " <> _, _}) do
  end

  defp exec_command(_) do
  end

  defp persist_subscription(command, url) do
    exec_operation(fn ->
      %Subscription{
        user_id: command["message"]["from"]["id"],
        url: url,
        enabled: true
      } |> Subscription.write
    end)
  end
end
