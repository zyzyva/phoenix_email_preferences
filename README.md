# PhoenixEmailPreferences

Email preference management for Phoenix applications with phx.gen.auth.

## Features

- ✅ Opt-in/opt-out preference management
- ✅ Email preference history with full audit trail
- ✅ Secure unsubscribe tokens for email links
- ✅ Phoenix LiveView UI with real-time updates
- ✅ Comprehensive test generation (30+ tests)
- ✅ Compatible with Phoenix authentication generators
- ✅ Telemetry events for monitoring
- ✅ Mobile-responsive design
- ✅ Dark mode support
- ✅ Automatic default preferences on user creation
- ✅ Full removal task for easy cleanup

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_email_preferences, github: "zyzyva/phoenix_email_preferences"}
  ]
end
```

## Usage

Run the generator:

```bash
mix phx.gen.email_preferences
```

This will create:
- Database migrations
- Ecto schemas
- Context module
- LiveView pages
- Function components

Then run migrations:

```bash
mix ecto.migrate
```

Customize email preferences in `priv/email_preferences.json`:
- Edit preference types, categories, and descriptions
- Set which preferences are required (`can_opt_out: false`)
- Configure default opt-in preferences (`default_opted_in: true`)

Add routes to your `router.ex`:

```elixir
scope "/", YourAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live "/settings/email-preferences", EmailPreferencesLive, :index
end

scope "/", YourAppWeb do
  pipe_through :browser

  live "/unsubscribe/:token", UnsubscribeLive, :show
end
```

## How It Works

### Default Preferences
When a user first accesses their email preferences (or when preferences are fetched), the system automatically initializes them based on the configuration in `priv/email_preferences.json`. Preferences marked with `default_opted_in: true` will have the user opted in by default.

This approach:
- ✅ Provides sensible defaults without requiring user action
- ✅ Reduces friction for new users
- ✅ Complies with CAN-SPAM (US) - users can unsubscribe from any email
- ✅ Users can change preferences anytime at `/settings/email-preferences`

### Managing Preferences
Users can view and update their email preferences at `/settings/email-preferences`. Every email sent should include an unsubscribe link to `/unsubscribe/:token` where users can quickly opt out of specific email types.

**Note:** If you need explicit opt-in consent (e.g., for GDPR compliance), set `default_opted_in: false` in your `priv/email_preferences.json` configuration and implement your own onboarding flow.

## Optional: First-Login Modal

If you want users to review their email preferences on first login (even though they have defaults), you can add the modal:

1. Add the hook to your authenticated live_session in `router.ex`:

```elixir
live_session :require_authenticated_user,
  on_mount: [
    {YourAppWeb.UserAuth, :ensure_authenticated},
    {YourAppWeb.EmailPreferencesHook, :show_email_preferences_modal}
  ] do
  # ... your authenticated routes ...
end
```

2. Add the modal component to your root layout (`lib/your_app_web/components/layouts/root.html.heex`):

```heex
<.live_component
  :if={assigns[:show_email_preferences_modal]}
  module={YourAppWeb.EmailPreferencesModal}
  id="email-preferences-modal"
  current_user={@current_user}
/>
```

**Note:** With automatic defaults enabled, the modal will only show if the user has no preference records at all. To force the modal to show even with defaults, you'll need to modify the `needs_preference_setup?/1` function in your EmailPreferences context to track whether preferences were explicitly set vs auto-initialized.

## Removing Email Preferences

If you need to remove the email preferences functionality from your application, use the removal task:

```bash
mix phx.gen.email_preferences.remove
```

This will:
- Roll back the database migrations (if applied)
- Remove all generated files
- Provide instructions for manually removing routes

### Removal Options

- `--no-rollback` - Skip rolling back migrations (only remove files)
- `--force` - Don't prompt for confirmation

```bash
# Remove without rolling back migrations
mix phx.gen.email_preferences.remove --no-rollback

# Remove without confirmation prompt
mix phx.gen.email_preferences.remove --force
```

## Preference Types

Default types:
- `marketing` - Marketing emails
- `newsletter` - Newsletter
- `product_updates` - Product updates
- `tips` - Tips and tutorials

Customize in your app's schemas.

## License

MIT

