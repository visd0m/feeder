defmodule FeederBot.Repo.Migrations.AddSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :user_id, :string
      add :chat_id, :string
      add :url, :string
      add :tag, :string
      add :last_update, :integer
      add :enabled, :boolean
      
      timestamps
    end
  end
end
