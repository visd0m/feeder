defmodule FeederBot.LogDeleter do

  def delete_logs do
    File.rm!("/logs/app.log")
  end

end
