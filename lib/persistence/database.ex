require Amnesia
use Amnesia

defdatabase Feeder.Persistence.Database do
  deftable Subscription, [{:id, autoincrement}, :user_id, :url], type: :ordered_set, index: [:user_id] do
  end
end
