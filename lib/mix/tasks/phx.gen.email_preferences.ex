defmodule Mix.Tasks.Phx.Gen.EmailPreferences do
  @shortdoc "Generates email preferences management"
  @moduledoc """
  Generates email preference management for a Phoenix application.

  This task generates:
    * Database migrations for user_email_preferences and email_preference_history
    * Ecto schemas
    * LiveView pages for preference management
    * Function components for opt-in checkboxes

  ## Usage

      $ mix phx.gen.email_preferences

  ## Requirements

  This generator assumes your application uses `phx.gen.auth` and has:
    * A `users` table in the database
    * Phoenix LiveView installed
    * Ecto configured

  """

  use Mix.Task

  # Embedded templates
  @migration_user_preferences_template File.read!(Path.join([__DIR__, "../../../priv/templates/migration_user_preferences.txt"]))
  @migration_preference_history_template File.read!(Path.join([__DIR__, "../../../priv/templates/migration_preference_history.txt"]))
  @user_preference_template File.read!(Path.join([__DIR__, "../../../priv/templates/user_preference.txt"]))
  @preference_history_template File.read!(Path.join([__DIR__, "../../../priv/templates/preference_history.txt"]))
  @email_preferences_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.txt"]))
  @config_template File.read!(Path.join([__DIR__, "../../../priv/templates/config.ex.txt"]))
  @json_config_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.json"]))
  @telemetry_template File.read!(Path.join([__DIR__, "../../../priv/templates/telemetry.txt"]))
  @email_preferences_components_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_components.txt"]))
  @email_preferences_live_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_live.txt"]))
  @unsubscribe_live_template File.read!(Path.join([__DIR__, "../../../priv/templates/unsubscribe_live.txt"]))
  @email_preferences_modal_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_modal.txt"]))
  @email_preferences_hook_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_hook.txt"]))
  # Test templates
  @email_preferences_test_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_test.txt"]))
  @unsubscribe_live_test_template File.read!(Path.join([__DIR__, "../../../priv/templates/unsubscribe_live_test.txt"]))
  @email_preferences_context_test_template File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_context_test.txt"]))

  @impl Mix.Task
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.email_preferences must be invoked from within your *_web application root directory")
    end

    context_app = Mix.Phoenix.context_app()
    web_prefix = Mix.Phoenix.web_path(context_app)
    context_lib_path = Mix.Phoenix.context_lib_path(context_app, "")

    base_module = Macro.camelize(Atom.to_string(context_app))

    binding = [
      context_app: context_app,
      web_module: "#{base_module}Web",
      app_module: base_module,
      app_name: Atom.to_string(context_app)
    ]

    Mix.Phoenix.check_module_name_availability!(Module.concat([context_app, "EmailPreferences"]))

    # Generate files directly from embedded templates
    generate_files(context_app, web_prefix, context_lib_path, binding)

    print_shell_instructions(binding)
  end

  defp generate_files(_context_app, web_prefix, context_lib_path, binding) do
    # Create directories
    File.mkdir_p!(Path.join([context_lib_path, "email_preferences"]))
    File.mkdir_p!(Path.join([web_prefix, "components"]))
    File.mkdir_p!(Path.join([web_prefix, "live"]))
    File.mkdir_p!("priv/repo/migrations")

    # Check if migrations already exist
    existing_migrations = Path.wildcard("priv/repo/migrations/*_create_user_email_preferences.exs") ++
                          Path.wildcard("priv/repo/migrations/*_create_email_preference_history.exs")

    if Enum.empty?(existing_migrations) do
      # Generate migrations only if they don't exist
      migration_user_prefs = Path.join(["priv/repo/migrations", "#{timestamp()}_create_user_email_preferences.exs"])
      File.write!(migration_user_prefs, render_template(@migration_user_preferences_template, binding))
      Mix.shell().info([:green, "* creating ", :reset, migration_user_prefs])

      migration_history = Path.join(["priv/repo/migrations", "#{timestamp() + 1}_create_email_preference_history.exs"])
      File.write!(migration_history, render_template(@migration_preference_history_template, binding))
      Mix.shell().info([:green, "* creating ", :reset, migration_history])
    else
      Enum.each(existing_migrations, fn path ->
        Mix.shell().info([:yellow, "* skipping ", :reset, path, " (already exists)"])
      end)
    end

    # Generate schemas
    schema_user_pref = Path.join([context_lib_path, "email_preferences/user_preference.ex"])
    create_or_skip(schema_user_pref, render_template(@user_preference_template, binding))

    schema_history = Path.join([context_lib_path, "email_preferences/preference_history.ex"])
    create_or_skip(schema_history, render_template(@preference_history_template, binding))

    # Generate context
    context_file = Path.join([context_lib_path, "email_preferences.ex"])
    create_or_skip(context_file, render_template(@email_preferences_template, binding))

    # Generate Config module
    config_file = Path.join([context_lib_path, "email_preferences/config.ex"])
    create_or_skip(config_file, render_template(@config_template, binding))

    # Copy JSON configuration file
    json_config_file = Path.join(["priv", "email_preferences.json"])
    create_or_skip(json_config_file, render_template(@json_config_template, binding))

    telemetry_file = Path.join([context_lib_path, "email_preferences/telemetry.ex"])
    create_or_skip(telemetry_file, render_template(@telemetry_template, binding))

    # Generate components
    components_file = Path.join([web_prefix, "components/email_preferences_components.ex"])
    create_or_skip(components_file, render_template(@email_preferences_components_template, binding))

    # Generate LiveViews
    live_file = Path.join([web_prefix, "live/email_preferences_live.ex"])
    create_or_skip(live_file, render_template(@email_preferences_live_template, binding))

    unsubscribe_file = Path.join([web_prefix, "live/unsubscribe_live.ex"])
    create_or_skip(unsubscribe_file, render_template(@unsubscribe_live_template, binding))

    # Generate modal and hook
    modal_file = Path.join([web_prefix, "live/email_preferences_modal.ex"])
    create_or_skip(modal_file, render_template(@email_preferences_modal_template, binding))

    hook_file = Path.join([web_prefix, "hooks/email_preferences_hook.ex"])
    File.mkdir_p!(Path.dirname(hook_file))
    create_or_skip(hook_file, render_template(@email_preferences_hook_template, binding))

    # Generate test files
    test_dir = "test/#{binding[:context_app]}_web/live"
    File.mkdir_p!(test_dir)

    email_prefs_test = Path.join([test_dir, "email_preferences_live_test.exs"])
    create_or_skip(email_prefs_test, render_template(@email_preferences_test_template, binding))

    unsubscribe_test = Path.join([test_dir, "unsubscribe_live_test.exs"])
    create_or_skip(unsubscribe_test, render_template(@unsubscribe_live_test_template, binding))

    context_test_dir = "test/#{binding[:context_app]}"
    File.mkdir_p!(context_test_dir)

    context_test = Path.join([context_test_dir, "email_preferences_test.exs"])
    create_or_skip(context_test, render_template(@email_preferences_context_test_template, binding))
  end

  defp create_or_skip(path, content) do
    if File.exists?(path) do
      Mix.shell().info([:yellow, "* skipping ", :reset, path, " (already exists)"])
    else
      File.write!(path, content)
      Mix.shell().info([:green, "* creating ", :reset, path])
    end
  end

  defp render_template(template, binding) do
    Enum.reduce(binding, template, fn {key, value}, acc ->
      String.replace(acc, "<%= @#{key} %>", to_string(value))
    end)
  end

  defp print_shell_instructions(binding) do
    Mix.shell().info("""

    Email preferences have been generated!

    Next steps:

    1. Run migrations:

        $ mix ecto.migrate

    2. Customize email preferences in priv/email_preferences.json
       - Edit preference types, categories, and descriptions
       - Set which preferences are required (can_opt_out: false)
       - Configure default opt-in preferences

    3. Add the first-login modal hook to your authenticated live_session:

        live_session :require_authenticated_user,
          on_mount: [
            {#{binding[:web_module]}.UserAuth, :ensure_authenticated},
            {#{binding[:web_module]}.EmailPreferencesHook, :show_email_preferences_modal}
          ] do
          # ... your authenticated routes ...
        end

    4. Add the modal component to your root layout or app layout:

        In lib/#{binding[:context_app]}_web/components/layouts/app.html.heex, add:

        <.live_component
          :if={assigns[:show_email_preferences_modal]}
          module={#{binding[:web_module]}.EmailPreferencesModal}
          id="email-preferences-modal"
          current_user={@current_user}
        />

    5. Add routes to your router.ex:

        # Add to your existing authenticated live_session (with phx.gen.auth on_mount)
        scope "/", #{binding[:web_module]} do
          pipe_through [:browser, :require_authenticated_user]

          live_session :require_authenticated_user,
            on_mount: [{#{binding[:web_module]}.UserAuth, :ensure_authenticated}] do
            # ... your other authenticated routes ...
            live "/settings/email-preferences", EmailPreferencesLive, :index
          end
        end

        # Add to your public live_session (or create one if needed)
        scope "/", #{binding[:web_module]} do
          pipe_through :browser

          live_session :public,
            on_mount: [{#{binding[:web_module]}.UserAuth, :mount_current_user}] do
            live "/unsubscribe/:token", UnsubscribeLive, :show
          end
        end

        Note: The EmailPreferencesLive module works with both authentication patterns:
        - socket.assigns.current_user (standard phx.gen.auth)
        - socket.assigns.current_scope.user (custom auth patterns)

    6. Run the generated tests to verify everything is working:

        $ mix test test/#{binding[:context_app]}_web/live/email_preferences_live_test.exs
        $ mix test test/#{binding[:context_app]}_web/live/unsubscribe_live_test.exs
        $ mix test test/#{binding[:context_app]}/email_preferences_test.exs

    """)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    |> String.to_integer()
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
