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

  @impl Mix.Task
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.email_preferences must be invoked from within your *_web application root directory")
    end

    context_app = Mix.Phoenix.context_app()
    web_prefix = Mix.Phoenix.web_path(context_app)
    context_lib_path = Mix.Phoenix.context_lib_path(context_app, "")

    binding = [
      context_app: context_app,
      web_module: Module.concat([Macro.camelize(Atom.to_string(context_app)), "Web"]),
      app_module: Macro.camelize(Atom.to_string(context_app))
    ]

    Mix.Phoenix.check_module_name_availability!(Module.concat([context_app, "EmailPreferences"]))

    paths = generator_paths()

    files =
      [
        # Migrations
        {:eex, "migration_user_preferences.exs.eex", Path.join(["priv/repo/migrations", "#{timestamp()}_create_user_email_preferences.exs"])},
        {:eex, "migration_preference_history.exs.eex", Path.join(["priv/repo/migrations", "#{timestamp() + 1}_create_email_preference_history.exs"])},
        # Schemas
        {:eex, "user_preference.ex.eex", Path.join([context_lib_path, "email_preferences/user_preference.ex"])},
        {:eex, "preference_history.ex.eex", Path.join([context_lib_path, "email_preferences/preference_history.ex"])},
        # Context
        {:eex, "email_preferences.ex.eex", Path.join([context_lib_path, "email_preferences.ex"])},
        {:eex, "telemetry.ex.eex", Path.join([context_lib_path, "email_preferences/telemetry.ex"])},
        # Components
        {:eex, "email_preferences_components.ex.eex", Path.join([web_prefix, "components/email_preferences_components.ex"])},
        # LiveViews
        {:eex, "email_preferences_live.ex.eex", Path.join([web_prefix, "live/email_preferences_live.ex"])},
        {:eex, "unsubscribe_live.ex.eex", Path.join([web_prefix, "live/unsubscribe_live.ex"])}
      ]

    Mix.Phoenix.copy_from(paths, "priv/templates", binding, files)

    print_shell_instructions(binding)
  end

  defp generator_paths do
    [".", :phoenix_email_preferences]
  end

  defp print_shell_instructions(binding) do
    Mix.shell().info("""

    Email preferences have been generated!

    Next steps:

    1. Run migrations:

        $ mix ecto.migrate

    2. Add routes to your router.ex:

        scope "/", #{binding[:web_module]} do
          pipe_through [:browser, :require_authenticated_user]

          live "/settings/email-preferences", EmailPreferencesLive, :index
        end

        scope "/", #{binding[:web_module]} do
          pipe_through :browser

          live "/unsubscribe/:token", UnsubscribeLive, :show
        end

    3. Add to your user registration form:

        <.signup_preferences
          preferences={EmailPreferences.preference_types()}
          checked_types={["newsletter"]}
        />

    4. Handle preferences in your registration controller:

        preferences = Map.get(user_params, "preferences", %{})
        EmailPreferences.set_preferences(user.id, preferences, %{source: "signup"})

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
