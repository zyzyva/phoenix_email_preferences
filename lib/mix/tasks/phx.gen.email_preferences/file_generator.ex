defmodule Mix.Tasks.Phx.Gen.EmailPreferences.FileGenerator do
  @moduledoc """
  Handles file generation and creation for email preferences.
  """

  alias Mix.Tasks.Phx.Gen.EmailPreferences.TemplateLoader

  @doc """
  Generates all necessary files for email preferences.
  """
  def generate_all(_context_app, web_prefix, context_lib_path, binding, templates) do
    create_directories(context_lib_path, web_prefix, binding)

    generate_migrations(templates, binding)
    generate_schemas(context_lib_path, templates, binding)
    generate_context(context_lib_path, templates, binding)
    generate_config(context_lib_path, templates, binding)
    generate_json_config(templates, binding)
    generate_telemetry(context_lib_path, templates, binding)
    generate_components(web_prefix, templates, binding)
    generate_liveviews(web_prefix, templates, binding)
    generate_modal_and_hook(web_prefix, templates, binding)
    generate_tests(binding, templates)
  end

  defp create_directories(context_lib_path, web_prefix, binding) do
    directories = [
      Path.join([context_lib_path, "email_preferences"]),
      Path.join([web_prefix, "components"]),
      Path.join([web_prefix, "live"]),
      Path.join([web_prefix, "hooks"]),
      "priv/repo/migrations",
      "test/#{binding[:context_app]}_web/live",
      "test/#{binding[:context_app]}"
    ]

    Enum.each(directories, &File.mkdir_p!/1)
  end

  defp generate_migrations(templates, binding) do
    existing_migrations =
      Path.wildcard("priv/repo/migrations/*_create_user_email_preferences.exs") ++
        Path.wildcard("priv/repo/migrations/*_create_email_preference_history.exs")

    if Enum.empty?(existing_migrations) do
      migration_user_prefs = migration_path("create_user_email_preferences")

      create_file(
        migration_user_prefs,
        TemplateLoader.render(templates.migration_user_preferences, binding)
      )

      migration_history = migration_path("create_email_preference_history", 1)

      create_file(
        migration_history,
        TemplateLoader.render(templates.migration_preference_history, binding)
      )
    else
      Enum.each(existing_migrations, fn path ->
        Mix.shell().info([:yellow, "* skipping ", :reset, path, " (already exists)"])
      end)
    end
  end

  defp generate_schemas(context_lib_path, templates, binding) do
    files = [
      {Path.join([context_lib_path, "email_preferences/user_preference.ex"]),
       templates.user_preference},
      {Path.join([context_lib_path, "email_preferences/preference_history.ex"]),
       templates.preference_history}
    ]

    Enum.each(files, fn {path, template} ->
      create_or_skip(path, TemplateLoader.render(template, binding))
    end)
  end

  defp generate_context(context_lib_path, templates, binding) do
    context_file = Path.join([context_lib_path, "email_preferences.ex"])
    create_or_skip(context_file, TemplateLoader.render(templates.email_preferences, binding))
  end

  defp generate_config(context_lib_path, templates, binding) do
    config_file = Path.join([context_lib_path, "email_preferences/config.ex"])
    create_or_skip(config_file, TemplateLoader.render(templates.config, binding))
  end

  defp generate_json_config(templates, binding) do
    json_config_file = Path.join(["priv", "email_preferences.json"])
    create_or_skip(json_config_file, TemplateLoader.render(templates.json_config, binding))
  end

  defp generate_telemetry(context_lib_path, templates, binding) do
    telemetry_file = Path.join([context_lib_path, "email_preferences/telemetry.ex"])
    create_or_skip(telemetry_file, TemplateLoader.render(templates.telemetry, binding))
  end

  defp generate_components(web_prefix, templates, binding) do
    components_file = Path.join([web_prefix, "components/email_preferences_components.ex"])

    create_or_skip(
      components_file,
      TemplateLoader.render(templates.email_preferences_components, binding)
    )
  end

  defp generate_liveviews(web_prefix, templates, binding) do
    files = [
      {Path.join([web_prefix, "live/email_preferences_live.ex"]),
       templates.email_preferences_live},
      {Path.join([web_prefix, "live/unsubscribe_live.ex"]), templates.unsubscribe_live}
    ]

    Enum.each(files, fn {path, template} ->
      create_or_skip(path, TemplateLoader.render(template, binding))
    end)
  end

  defp generate_modal_and_hook(web_prefix, templates, binding) do
    modal_file = Path.join([web_prefix, "live/email_preferences_modal.ex"])
    create_or_skip(modal_file, TemplateLoader.render(templates.email_preferences_modal, binding))

    hook_file = Path.join([web_prefix, "hooks/email_preferences_hook.ex"])
    create_or_skip(hook_file, TemplateLoader.render(templates.email_preferences_hook, binding))
  end

  defp generate_tests(binding, templates) do
    test_dir = "test/#{binding[:context_app]}_web/live"
    context_test_dir = "test/#{binding[:context_app]}"

    files = [
      {Path.join([test_dir, "email_preferences_live_test.exs"]),
       templates.email_preferences_test},
      {Path.join([test_dir, "unsubscribe_live_test.exs"]), templates.unsubscribe_live_test},
      {Path.join([context_test_dir, "email_preferences_test.exs"]),
       templates.email_preferences_context_test}
    ]

    Enum.each(files, fn {path, template} ->
      create_or_skip(path, TemplateLoader.render(template, binding))
    end)
  end

  defp create_or_skip(path, content) do
    if File.exists?(path) do
      Mix.shell().info([:yellow, "* skipping ", :reset, path, " (already exists)"])
    else
      create_file(path, content)
    end
  end

  defp create_file(path, content) do
    File.write!(path, content)
    Mix.shell().info([:green, "* creating ", :reset, path])
  end

  defp migration_path(name, offset \\ 0) do
    timestamp_int = timestamp() + offset
    Path.join(["priv/repo/migrations", "#{timestamp_int}_#{name}.exs"])
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    year_int = y * 10_000_000_000
    month_int = m * 100_000_000
    day_int = d * 1_000_000
    hour_int = hh * 10000
    min_int = mm * 100
    year_int + month_int + day_int + hour_int + min_int + ss
  end
end
