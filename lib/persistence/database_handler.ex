defmodule FeederBot.Persistence.DatabaseHandler do
  use GenServer
  require Amnesia
  require Amnesia.Helper

  def exec_operation(function) do
    Amnesia.transaction do
      function.()
    end
  end
end
