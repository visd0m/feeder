defmodule Feeder.Telegram.MessageHandler do
  alias :mnesia, as: Mnesia
  require Logger

  def handle_commands(commands) do
    commands
      |> Enum.filter(fn(message_wrapper) -> String.contains?(message_wrapper["message"]["text"], "/subscribe") end)
      |> handle_subscriptions
  end

  defp handle_subscriptions(subscriptions) do
    subscriptions
      |> Enum.map(fn(message_wrapper) ->
        fn -> persist_subscription(
          message_wrapper["message"]["from"]["id"],
          List.last(String.split(message_wrapper["message"]["text"], " "))
        ) end
      end)
      |> Enum.each(fn(data_to_write) -> Mnesia.transaction(data_to_write) end)
  end

  defp persist_subscription(id, url) do
    Mnesia.write({Subscription, Ecto.UUID, id, url})
  end
end
