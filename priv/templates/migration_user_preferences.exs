defmodule <%= @app_module %>.Repo.Migrations.CreateUserEmailPreferences do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:user_email_preferences) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :preference_type, :string, null: false
      add :opted_in, :boolean, null: false, default: false
      add :opted_in_at, :utc_datetime
      add :opted_out_at, :utc_datetime
      add :ip_address, :string
      add :user_agent, :text
      add :source, :string

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:user_email_preferences, [:user_id, :preference_type])
    create_if_not_exists index(:user_email_preferences, [:user_id])
    create_if_not_exists index(:user_email_preferences, [:preference_type])
  end

  def down do
    drop_if_exists index(:user_email_preferences, [:preference_type])
    drop_if_exists index(:user_email_preferences, [:user_id])
    drop_if_exists unique_index(:user_email_preferences, [:user_id, :preference_type])
    drop_if_exists table(:user_email_preferences)
  end
end
