defmodule <%= @app_module %>.EmailPreferences do
  @moduledoc """
  Email preference management context.
  """

  import Ecto.Query
  alias <%= @app_module %>.Repo
  alias <%= @app_module %>.EmailPreferences.UserPreference
  alias <%= @app_module %>.EmailPreferences.PreferenceHistory
  alias <%= @app_module %>.EmailPreferences.Telemetry

  @preference_types ~w(marketing newsletter product_updates tips)

  def preference_types, do: @preference_types

  def get_user_preferences(user_id) do
    Repo.all(from p in UserPreference, where: p.user_id == ^user_id)
  end

  def get_preference(user_id, preference_type) do
    Repo.get_by(UserPreference, user_id: user_id, preference_type: to_string(preference_type))
  end

  def has_consented?(user_id, preference_type) do
    case get_preference(user_id, preference_type) do
      %UserPreference{opted_in: true} -> {:ok, true}
      %UserPreference{opted_in: false} -> {:ok, false}
      nil -> {:ok, false}
    end
  end

  def opt_in(user_id, preference_type, attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = Map.merge(attrs, %{
      user_id: user_id,
      preference_type: to_string(preference_type),
      opted_in: true,
      opted_in_at: now,
      opted_out_at: nil
    })

    result = %UserPreference{}
    |> UserPreference.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:opted_in, :opted_in_at, :opted_out_at, :updated_at]},
      conflict_target: [:user_id, :preference_type]
    )

    case result do
      {:ok, preference} ->
        record_history(user_id, preference_type, :opt_in, true, attrs)
        Telemetry.track_opt_in(preference_type, attrs[:source] || "unknown")
        {:ok, preference}

      error ->
        error
    end
  end

  def opt_out(user_id, preference_type, attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = Map.merge(attrs, %{
      user_id: user_id,
      preference_type: to_string(preference_type),
      opted_in: false,
      opted_in_at: nil,
      opted_out_at: now
    })

    result = %UserPreference{}
    |> UserPreference.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:opted_in, :opted_in_at, :opted_out_at, :updated_at]},
      conflict_target: [:user_id, :preference_type]
    )

    case result do
      {:ok, preference} ->
        record_history(user_id, preference_type, :opt_out, false, attrs)
        Telemetry.track_opt_out(preference_type, attrs[:source] || "unknown")
        {:ok, preference}

      error ->
        error
    end
  end

  def set_preferences(user_id, preferences_map, attrs \\ %{}) do
    Enum.each(preferences_map, fn {preference_type, opted_in} ->
      if opted_in do
        opt_in(user_id, preference_type, attrs)
      else
        opt_out(user_id, preference_type, attrs)
      end
    end)

    {:ok, get_user_preferences(user_id)}
  end

  def generate_unsubscribe_token(user_id, preference_type) do
    Phoenix.Token.sign(
      <%= @web_module %>.Endpoint,
      "unsubscribe",
      %{user_id: user_id, preference_type: to_string(preference_type)},
      max_age: 30 * 24 * 60 * 60  # 30 days
    )
  end

  def verify_unsubscribe_token(token) do
    case Phoenix.Token.verify(
      <%= @web_module %>.Endpoint,
      "unsubscribe",
      token,
      max_age: 30 * 24 * 60 * 60
    ) do
      {:ok, %{user_id: user_id, preference_type: preference_type}} ->
        {:ok, {user_id, preference_type}}

      {:error, :expired} ->
        {:error, :expired}

      {:error, _} ->
        {:error, :invalid}
    end
  end

  defp record_history(user_id, preference_type, action, opted_in, attrs) do
    %PreferenceHistory{}
    |> PreferenceHistory.changeset(%{
      user_id: user_id,
      preference_type: to_string(preference_type),
      action: to_string(action),
      opted_in: opted_in,
      ip_address: attrs[:ip_address],
      user_agent: attrs[:user_agent],
      source: attrs[:source],
      metadata: attrs[:metadata]
    })
    |> Repo.insert()
  end
end
