defmodule Feeder.Telegram.MessageHandler do
  alias :mnesia, as: Mnesia
  require Logger

  def handle_commands(commands) do
    subscriptions = commands
      |> Enum.filter(fn(message_wrapper) ->
        String.contains?(message_wrapper["message"]["text"], "/subscribe")
      end)
    Logger.info("subscriptions found: #{inspect(subscriptions)}")

    handle_subscriptions(subscriptions)
  end

  defp handle_subscriptions(subscriptions) do
    subscriptions
      |> Enum.map(fn(message_wrapper) ->
        fn ->
          Mnesia.write({
            Subscription,
            Ecto.UUID,
            message_wrapper["message"]["from"]["id"],
            List.last(String.split(message_wrapper["message"]["text"], " "))
            })
        end
      end)
      |> Enum.each(fn(data_to_write) ->
        Logger.info("data_to_write: #{inspect(data_to_write)}")
        Logger.info("mnesia write result: #{inspect(Mnesia.transaction(data_to_write))}")
        record = Mnesia.transaction(fn -> Mnesia.read({Subscription, 1}) end)
        Logger.info("data_read: #{inspect(record)}")
      end)
  end
end
