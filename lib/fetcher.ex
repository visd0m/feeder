defmodule Feeder.Fetcher do
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
    messages = Feeder.Telegram.TelegramService.fetch_messages(last_id)

    new_last_id = List.last(messages)["update_id"]
    {:reply, messages, new_last_id}
  end
end
