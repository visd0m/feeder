defmodule FeederBot.Persistence.Subscription do
    use Ecto.Schema
    import Ecto.Changeset

    schema "subscriptions" do
        field :user_id, :string
        field :chat_id, :string
        field :url, :string
        field :tag, :string
        field :last_update, :integer
        field :enabled, :boolean
        
        timestamps
    end

    def changeset(subscription, params \\ %{}) do
        subscription
        |> cast(params, [:enabled, :last_update, :tag])
    end
end