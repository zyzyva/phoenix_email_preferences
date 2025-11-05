defmodule Mix.Tasks.Phx.Gen.EmailPreferences.ShellInstructions do
  @moduledoc """
  Prints shell instructions after generating email preferences.
  """

  @doc """
  Prints instructions for the user to follow after generation.
  """
  def print(binding) do
    Mix.shell().info("""

    Email preferences have been generated!

    Next steps:

    1. Run migrations:

        $ mix ecto.migrate

    2. Customize email preferences in priv/email_preferences.json
       - Edit preference types, categories, and descriptions
       - Set which preferences are required (can_opt_out: false)
       - Configure default opt-in preferences (default_opted_in: true)

    3. Add routes to your router.ex:

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

    4. How it works:
       - Users automatically get default preferences (from priv/email_preferences.json)
       - They can manage preferences anytime at /settings/email-preferences
       - Every email should include an unsubscribe link to /unsubscribe/:token
       - CAN-SPAM compliant for US users (opt-out model)

    5. (Optional) First-login modal:
       If you want users to review preferences on first login, see the README
       for instructions on adding the EmailPreferencesHook and modal component.

    6. Run the generated tests to verify everything is working:

        $ mix test test/#{binding[:context_app]}_web/live/email_preferences_live_test.exs
        $ mix test test/#{binding[:context_app]}_web/live/unsubscribe_live_test.exs
        $ mix test test/#{binding[:context_app]}/email_preferences_test.exs
    """)
  end
end
