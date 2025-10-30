# PhoenixEmailPreferences

Email preference management for Phoenix applications with phx.gen.auth.

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

## Features

- Opt-in/opt-out management
- Email preference history (audit trail)
- Unsubscribe tokens
- LiveView UI
- Telemetry events
- Mobile-responsive

## Preference Types

Default types:
- `marketing` - Marketing emails
- `newsletter` - Newsletter
- `product_updates` - Product updates
- `tips` - Tips and tutorials

Customize in your app's schemas.

## License

MIT

