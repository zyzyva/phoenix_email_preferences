defmodule <%= @app_module %>.Repo.Migrations.CreateEmailPreferenceHistory do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:email_preference_history) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :preference_type, :string, null: false
      add :action, :string, null: false
      add :opted_in, :boolean, null: false
      add :ip_address, :string
      add :user_agent, :text
      add :source, :string
      add :metadata, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create_if_not_exists index(:email_preference_history, [:user_id])
    create_if_not_exists index(:email_preference_history, [:user_id, :preference_type])
    create_if_not_exists index(:email_preference_history, [:inserted_at])
  end

  def down do
    drop_if_exists index(:email_preference_history, [:inserted_at])
    drop_if_exists index(:email_preference_history, [:user_id, :preference_type])
    drop_if_exists index(:email_preference_history, [:user_id])
    drop_if_exists table(:email_preference_history)
  end
end
