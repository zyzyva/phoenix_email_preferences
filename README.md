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

