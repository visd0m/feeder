defmodule FeederBot.Persistence.SubscriptionDao do
  alias FeederBot.Persistence.Subscription, as: Subscription
  import Ecto.Query

  def insert(subscription) do
    FeederBot.Repo.insert(subscription)
  end

  def update(subscription, new_subscription) do
    changeset = Subscription.changeset(
      subscription, 
      %{enabled: new_subscription.enabled, last_update: new_subscription.last_update, tag: new_subscription.tag}
    )
    FeederBot.Repo.update!(changeset)
  end

  def load_all do
    query = from s in Subscription,
    select: s

    FeederBot.Repo.all(query)
  end

  def load_enabled do
    query = from s in Subscription,
    where: s.enabled == true,
    select: s

    FeederBot.Repo.all(query)
  end

  def load_enabled_by_user_id(user_id) do
    user_id = "#{user_id}"
    query = from s in Subscription,
            where: s.user_id == ^user_id and s.enabled == true,
            select: s

    FeederBot.Repo.all(query)
  end

  def load_enabled_by_user_and_tag(user_id, tag) do
    user_id = "#{user_id}"
    tag = "#{tag}"
    query = from s in Subscription,
    where: s.user_id == ^user_id and s.tag == ^tag and s.enabled == true,
    select: s

    FeederBot.Repo.all(query)
  end

  def load_enabled_by_user_id_and_url(user_id, url) do
    user_id = "#{user_id}"
    url = "#{url}"
    query = from s in Subscription,
    where: s.user_id == ^user_id and s.url == ^url and s.enabled == true,
    select: s

    FeederBot.Repo.all(query)
  end
end
