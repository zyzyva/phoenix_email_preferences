defmodule Mix.Tasks.Phx.Gen.EmailPreferences do
  @shortdoc "Generates email preferences management"
  @moduledoc """
  Generates email preference management for a Phoenix application.

  This task generates:
    * Database migrations for user_email_preferences and email_preference_history
    * Ecto schemas
    * LiveView pages for preference management
    * Function components for opt-in checkboxes
    * Router helpers

  ## Usage

      $ mix phx.gen.email_preferences

  ## Options

      * `--no-migrations` - Skip generating migrations
      * `--no-liveview` - Skip generating LiveView pages

  ## Requirements

  This generator assumes your application uses `phx.gen.auth` and has:
    * A `users` table in the database
    * Phoenix LiveView installed
    * Ecto configured

  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter, _argv) do
    igniter
    |> create_migrations()
    |> create_schemas()
    |> create_context_module()
    |> create_telemetry_module()
    |> create_components()
    |> create_liveviews()
    |> add_instructions()
  end

  defp create_migrations(igniter) do
    timestamp = timestamp()

    # Migration for user_email_preferences
    preferences_migration = """
    defmodule <%= @repo %>.Migrations.CreateUserEmailPreferences do
      use Ecto.Migration

      def change do
        create table(:user_email_preferences) do
          add :user_id, references(:users, on_delete: :delete_all), null: false
          add :preference_type, :string, null: false
          add :opted_in, :boolean, null: false, default: false
          add :opted_in_at, :utc_datetime
          add :opted_out_at, :utc_datetime
          add :ip_address, :string
          add :user_agent, :text
          add :source, :string

          timestamps(type: :utc_datetime)
        end

        create unique_index(:user_email_preferences, [:user_id, :preference_type])
        create index(:user_email_preferences, [:user_id])
        create index(:user_email_preferences, [:preference_type])
      end
    end
    """

    # Migration for email_preference_history
    history_migration = """
    defmodule <%= @repo %>.Migrations.CreateEmailPreferenceHistory do
      use Ecto.Migration

      def change do
        create table(:email_preference_history) do
          add :user_id, references(:users, on_delete: :delete_all), null: false
          add :preference_type, :string, null: false
          add :action, :string, null: false
          add :opted_in, :boolean, null: false
          add :ip_address, :string
          add :user_agent, :text
          add :source, :string
          add :metadata, :map

          timestamps(type: :utc_datetime, updated_at: false)
        end

        create index(:email_preference_history, [:user_id])
        create index(:email_preference_history, [:user_id, :preference_type])
        create index(:email_preference_history, [:inserted_at])
      end
    end
    """

    igniter
    |> Igniter.Project.IgniterConfig.setup()
    |> Igniter.Code.Module.find_and_update_or_create_module(
      Module.concat([Mix.Phoenix.context_app(), "Repo", "Migrations", "CreateUserEmailPreferences"]),
      fn zipper ->
        {:ok, zipper}
      end,
      path: "priv/repo/migrations/#{timestamp}_create_user_email_preferences.exs",
      contents: preferences_migration
    )
    |> Igniter.Code.Module.find_and_update_or_create_module(
      Module.concat([Mix.Phoenix.context_app(), "Repo", "Migrations", "CreateEmailPreferenceHistory"]),
      fn zipper ->
        {:ok, zipper}
      end,
      path: "priv/repo/migrations/#{timestamp + 1}_create_email_preference_history.exs",
      contents: history_migration
    )
  end

  defp create_schemas(igniter) do
    app = Mix.Phoenix.context_app()

    # UserPreference schema
    user_preference_schema = """
    defmodule #{inspect(Module.concat([app, "EmailPreferences", "UserPreference"]))} do
      use Ecto.Schema
      import Ecto.Changeset

      schema "user_email_preferences" do
        field :preference_type, :string
        field :opted_in, :boolean, default: false
        field :opted_in_at, :utc_datetime
        field :opted_out_at, :utc_datetime
        field :ip_address, :string
        field :user_agent, :string
        field :source, :string

        belongs_to :user, #{inspect(Module.concat([app, "Accounts", "User"]))}

        timestamps(type: :utc_datetime)
      end

      def changeset(user_preference, attrs) do
        user_preference
        |> cast(attrs, [:user_id, :preference_type, :opted_in, :opted_in_at, :opted_out_at, :ip_address, :user_agent, :source])
        |> validate_required([:user_id, :preference_type, :opted_in])
        |> validate_inclusion(:preference_type, ~w(marketing newsletter product_updates tips))
        |> unique_constraint([:user_id, :preference_type])
      end
    end
    """

    # PreferenceHistory schema
    preference_history_schema = """
    defmodule #{inspect(Module.concat([app, "EmailPreferences", "PreferenceHistory"]))} do
      use Ecto.Schema
      import Ecto.Changeset

      schema "email_preference_history" do
        field :preference_type, :string
        field :action, :string
        field :opted_in, :boolean
        field :ip_address, :string
        field :user_agent, :string
        field :source, :string
        field :metadata, :map

        belongs_to :user, #{inspect(Module.concat([app, "Accounts", "User"]))}

        timestamps(type: :utc_datetime, updated_at: false)
      end

      def changeset(history, attrs) do
        history
        |> cast(attrs, [:user_id, :preference_type, :action, :opted_in, :ip_address, :user_agent, :source, :metadata])
        |> validate_required([:user_id, :preference_type, :action, :opted_in])
        |> validate_inclusion(:action, ~w(opt_in opt_out))
      end
    end
    """

    igniter
    |> Igniter.Code.Module.create_module(
      Module.concat([app, "EmailPreferences", "UserPreference"]),
      user_preference_schema
    )
    |> Igniter.Code.Module.create_module(
      Module.concat([app, "EmailPreferences", "PreferenceHistory"]),
      preference_history_schema
    )
  end

  defp create_context_module(igniter) do
    app = Mix.Phoenix.context_app()

    context_module = """
    defmodule #{inspect(Module.concat([app, "EmailPreferences"]))} do
      @moduledoc \"\"\"
      Email preference management context.
      \"\"\"

      import Ecto.Query
      alias #{inspect(Module.concat([app, "Repo"]))}
      alias #{inspect(Module.concat([app, "EmailPreferences", "UserPreference"]))}
      alias #{inspect(Module.concat([app, "EmailPreferences", "PreferenceHistory"]))}

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

      def opt_in(user_id, preference_type, attrs \\\\ %{}) do
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
            {:ok, preference}

          error ->
            error
        end
      end

      def opt_out(user_id, preference_type, attrs \\\\ %{}) do
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
            {:ok, preference}

          error ->
            error
        end
      end

      def set_preferences(user_id, preferences_map, attrs \\\\ %{}) do
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
          #{inspect(Module.concat([app <> "Web", "Endpoint"]))},
          "unsubscribe",
          %{user_id: user_id, preference_type: to_string(preference_type)},
          max_age: 30 * 24 * 60 * 60  # 30 days
        )
      end

      def verify_unsubscribe_token(token) do
        case Phoenix.Token.verify(
          #{inspect(Module.concat([app <> "Web", "Endpoint"]))},
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
    """

    Igniter.Code.Module.create_module(igniter, Module.concat([app, "EmailPreferences"]), context_module)
  end

  defp create_telemetry_module(igniter) do
    app = Mix.Phoenix.context_app()

    telemetry_module = """
    defmodule #{inspect(Module.concat([app, "EmailPreferences", "Telemetry"]))} do
      @moduledoc false

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
    """

    Igniter.Code.Module.create_module(
      igniter,
      Module.concat([app, "EmailPreferences", "Telemetry"]),
      telemetry_module
    )
  end

  defp create_components(igniter) do
    app = Mix.Phoenix.context_app()
    web_module = Module.concat([app <> "Web"])

    components_path = Path.join(["lib", "#{Macro.underscore(app)}_web", "components", "email_preferences_components.ex"])
    template_path = Application.app_dir(:phoenix_email_preferences, "priv/templates/email_preferences_components.ex")

    case File.read(template_path) do
      {:ok, template} ->
        content = EEx.eval_string(template, assigns: [web_module: web_module])
        Igniter.create_new_file(igniter, components_path, content)

      {:error, _} ->
        # Template not found, skip
        igniter
    end
  end

  defp create_liveviews(igniter) do
    app = Mix.Phoenix.context_app()
    web_module = Module.concat([app <> "Web"])
    app_module = Module.concat([app])

    # Email preferences LiveView
    prefs_path = Path.join(["lib", "#{Macro.underscore(app)}_web", "live", "email_preferences_live.ex"])
    prefs_template = Application.app_dir(:phoenix_email_preferences, "priv/templates/email_preferences_live.ex")

    igniter = case File.read(prefs_template) do
      {:ok, template} ->
        content = EEx.eval_string(template, assigns: [web_module: web_module, app_module: app_module])
        Igniter.create_new_file(igniter, prefs_path, content)

      {:error, _} ->
        igniter
    end

    # Unsubscribe LiveView
    unsub_path = Path.join(["lib", "#{Macro.underscore(app)}_web", "live", "unsubscribe_live.ex"])
    unsub_template = Application.app_dir(:phoenix_email_preferences, "priv/templates/unsubscribe_live.ex")

    case File.read(unsub_template) do
      {:ok, template} ->
        content = EEx.eval_string(template, assigns: [web_module: web_module, app_module: app_module])
        Igniter.create_new_file(igniter, unsub_path, content)

      {:error, _} ->
        igniter
    end
  end

  defp add_instructions(igniter) do
    Igniter.add_notice(igniter, """

    Email preferences have been generated!

    Next steps:

    1. Run migrations:
        $ mix ecto.migrate

    2. Add routes to your router.ex:

        scope "/", YourAppWeb do
          pipe_through [:browser, :require_authenticated_user]

          live "/settings/email-preferences", EmailPreferencesLive, :index
        end

        scope "/", YourAppWeb do
          pipe_through :browser

          live "/unsubscribe/:token", UnsubscribeLive, :show
        end

    3. Add opt-in checkboxes to your registration form (see docs)

    4. Configure preference types in config.exs if you want to customize them

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
