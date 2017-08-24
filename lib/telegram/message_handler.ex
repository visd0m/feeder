defmodule Feeder.Telegram.MessageHandler do
  require Amnesia.Helper
  require Logger
  use Feeder.Persistence.Database

  def handle_command(command) do
    command
      |> parse_command
      |> exec_command
  end

  defp parse_command(command) do
    text = command["message"]["text"]

    if String.contains?(text, "/subscribe") do
      [_, url] = String.split(text, " ")
      {:subscribe, command, url}

    else
      if String.contains?(text, "/unsubscribe") do
        [_, url] = String.split(text, " ")
        {:unsubscribe, command, url}

      else
        {:unknwon, nil}

      end
    end
  end

  defp exec_command({:subscribe, command, url}) do
    persist_subscription(command, url)

    Feeder.Telegram.Fetcher.send_message({
      command["message"]["from"]["id"],
      "👾 subscription confirmed to '#{url}'"
    })
  end

  defp exec_command({:unsubscribe, _, _}) do
  end

  defp exec_command({:unknwon, _}) do
  end

  defp persist_subscription(command, url) do
    Amnesia.transaction do
        %Feeder.Persistence.Database.Subscription{
          user_id: command["message"]["from"]["id"],
          url: url,
          enabled: true
        } |> Feeder.Persistence.Database.Subscription.write

        records = Feeder.Persistence.Database.Subscription.where(id > 0)
          |> Amnesia.Selection.values
          |> Enum.to_list

        Logger.info("actual subscriptions: #{inspect(records)}")
    end
  end
end
