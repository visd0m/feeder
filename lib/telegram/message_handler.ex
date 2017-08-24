defmodule Feeder.Telegram.MessageHandler do
  require Amnesia.Helper
  require Logger
  use Feeder.Persistence.Database

  def handle_commands(commands) do
    case commands do
      [_ | _] ->
        commands
          |> Enum.filter(fn(message_wrapper) -> String.contains?(message_wrapper["message"]["text"], "/subscribe") end)
          |> handle_subscriptions
        _ ->
    end
  end

  defp handle_subscriptions(subscriptions) do
    Amnesia.transaction do
      subscriptions
        |> Enum.map(fn(message_wrapper) ->
          %Feeder.Persistence.Database.Subscription{
            user_id: message_wrapper["message"]["from"]["id"],
            url: List.last(String.split(message_wrapper["message"]["text"], " "))
          }
        end)
        |> Enum.each(fn(subscription) -> Feeder.Persistence.Database.Subscription.write(subscription) end)

        records = Feeder.Persistence.Database.Subscription.where(id > 0)
          |> Amnesia.Selection.values
          |> Enum.to_list

        Logger.info("actual subscriptions: #{inspect(records)}")
    end
  end
end
