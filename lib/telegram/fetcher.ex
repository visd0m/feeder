defmodule Feeder.Telegram.Fetcher do
  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch_messages() do
    GenServer.call(__MODULE__, :fetch)
  end

  # callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_call(:fetch, _from, last_id) do
    new_last_id = case messages = Feeder.Telegram.TelegramService.fetch_messages(last_id) do
      nil ->
        nil
      [] ->
        nil
      _ ->
        messages
          |> Enum.filter(fn(message_wrapper) ->
            case text = message_wrapper["message"]["text"] do
              nil ->
                false
              _ ->
                String.starts_with?(text, "/")
            end
          end)
          |> Feeder.Telegram.MessageHandler.handle_commands

        List.last(messages)["update_id"]
    end

    {:reply, messages, new_last_id}
  end
end
