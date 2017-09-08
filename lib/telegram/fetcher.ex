defmodule FeederBot.Telegram.Fetcher do
  require Logger
  use GenServer
  import FeederBot.Telegram
  import FeederBot.Telegram.Command

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch() do
    GenServer.call(__MODULE__, :fetch, 25000)
  end

  # ======== callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_call(:fetch, _from, last_id) do
    new_last_id = case messages = fetch_messages(last_id) do
      [_ | _] ->
        Task.Supervisor.async_nolink(FeederBot.TaskSupervisor, fn ->
          messages
            |> Enum.filter(&is_command(&1))
            |> Enum.map(fn(command) -> get_command_handler(command).() end)
            |> Enum.each(fn({_, message}) -> send_message(message) end)
        end)

        List.last(messages)["update_id"]
      _ ->
        nil
    end

    {:reply, messages, new_last_id}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
