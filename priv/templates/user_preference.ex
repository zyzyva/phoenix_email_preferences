defmodule <%= @app_module %>.EmailPreferences.UserPreference do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_email_preferences" do
    field :preference_type, :string
    field :opted_in, :boolean, default: false
    field :opted_in_at, :utc_datetime
    field :opted_out_at, :utc_datetime
    field :ip_address, :string
    field :user_agent, :string
    field :source, :string

    belongs_to :user, <%= @app_module %>.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(user_preference, attrs) do
    user_preference
    |> cast(attrs, [:user_id, :preference_type, :opted_in, :opted_in_at, :opted_out_at, :ip_address, :user_agent, :source])
    |> validate_required([:user_id, :preference_type, :opted_in])
    |> validate_inclusion(:preference_type, ~w(marketing newsletter product_updates tips))
    |> unique_constraint([:user_id, :preference_type])
  end
end
