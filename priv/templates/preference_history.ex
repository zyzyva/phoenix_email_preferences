defmodule <%= @app_module %>.EmailPreferences.PreferenceHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_preference_history" do
    field :preference_type, :string
    field :action, :string
    field :opted_in, :boolean
    field :ip_address, :string
    field :user_agent, :string
    field :source, :string
    field :metadata, :map

    belongs_to :user, <%= @app_module %>.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:user_id, :preference_type, :action, :opted_in, :ip_address, :user_agent, :source, :metadata])
    |> validate_required([:user_id, :preference_type, :action, :opted_in])
    |> validate_inclusion(:action, ~w(opt_in opt_out))
  end
end
