defmodule <%= @app_module %>.EmailPreferences.Telemetry do
  @moduledoc """
  Telemetry events for email preference tracking.
  """

  def track_opt_in(preference_type, source) do
    :telemetry.execute(
      [:phoenix_email_preferences, :opt_in],
      %{count: 1},
      %{preference_type: to_string(preference_type), source: to_string(source)}
    )
  end

  def track_opt_out(preference_type, source) do
    :telemetry.execute(
      [:phoenix_email_preferences, :opt_out],
      %{count: 1},
      %{preference_type: to_string(preference_type), source: to_string(source)}
    )
  end
end
