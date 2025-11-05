defmodule Mix.Tasks.Phx.Gen.EmailPreferences.TemplateLoader do
  @moduledoc """
  Handles loading and caching of EEx templates for email preferences generation.
  """

  @templates_dir Path.join([__DIR__, "../../../../priv/templates"])

  @doc """
  Loads all templates and returns them as a map.
  """
  def load_all do
    %{
      migration_user_preferences: load_template("migration_user_preferences.txt"),
      migration_preference_history: load_template("migration_preference_history.txt"),
      user_preference: load_template("user_preference.txt"),
      preference_history: load_template("preference_history.txt"),
      email_preferences: load_template("email_preferences.txt"),
      config: load_template("config.ex.txt"),
      json_config: load_template("email_preferences.json"),
      telemetry: load_template("telemetry.txt"),
      email_preferences_components: load_template("email_preferences_components.txt"),
      email_preferences_live: load_template("email_preferences_live.txt"),
      unsubscribe_live: load_template("unsubscribe_live.txt"),
      email_preferences_modal: load_template("email_preferences_modal.txt"),
      email_preferences_hook: load_template("email_preferences_hook.txt"),
      # Test templates
      email_preferences_test: load_template("email_preferences_test.txt"),
      unsubscribe_live_test: load_template("unsubscribe_live_test.txt"),
      email_preferences_context_test: load_template("email_preferences_context_test.txt")
    }
  end

  @doc """
  Renders a template with the given binding.
  """
  def render(template, binding) do
    Enum.reduce(binding, template, fn {key, value}, acc ->
      String.replace(acc, "<%= @#{key} %>", to_string(value))
    end)
  end

  defp load_template(filename) do
    path = Path.join(@templates_dir, filename)
    File.read!(path)
  rescue
    e in File.Error ->
      Mix.raise("Failed to load template #{filename}: #{inspect(e)}")
  end
end
