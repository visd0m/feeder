defmodule FeederBot.LogDeleter do
  def delete_logs do
    File.rm!("log/app.log")
  end
end
