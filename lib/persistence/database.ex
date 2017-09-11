require Amnesia
use Amnesia

defdatabase FeederBot.Persistence.Database do
  deftable Subscription,
           [
             {:id, autoincrement},
             :user_id,
             :chat_id,
             :url,
             :tag,
             :enabled,
             :last_update
           ],
           type:
             :ordered_set,
           index: [:user_id],
           index: [:url]
    do
  end

  def exec_operation(function) do
    Amnesia.transaction do
      function.()
    end
  end
end
