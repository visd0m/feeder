defmodule FeederBot.Persistence.SubscriptionDao do
  use FeederBot.Persistence.Database
  import FeederBot.Persistence.Database
  require FeederBot.Persistence.Database.Subscription

  def insert(subscription) do
    exec_operation(fn -> subscription |> Subscription.write end)
  end

  def update(subscription) do
    exec_operation(fn ->
        subscription |> Subscription.write
    end)
  end

  def load_all do
    exec_operation(fn ->
      Subscription.where(id >= 1)
        |> Amnesia.Selection.values
    end)
  end

  def load_enabled do
    exec_operation(fn ->
      Subscription.where(enabled == true)
        |> Amnesia.Selection.values
    end)
  end

  def load_enabled_by_user_id(id_p) do
    exec_operation(fn ->
      Subscription.where(user_id == id_p and enabled == true)
        |> Amnesia.Selection.values
    end)
  end

  def load_enabled_by_user_id_and_url(id_p, url_p) do
    exec_operation(fn ->
      Subscription.where(user_id == id_p and enabled == true and url == url_p)
        |> Amnesia.Selection.values
    end)
  end
end
