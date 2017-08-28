require Amnesia
use Amnesia

defdatabase FeederBot.Persistence.Database do
  deftable Subscription,
    [
      {:id, autoincrement},
      :user_id,
      :chat_id,
      :url,
      :enabled,
      :last_update
    ],
    type:
    :ordered_set,
    index: [:user_id] do
  end
end
