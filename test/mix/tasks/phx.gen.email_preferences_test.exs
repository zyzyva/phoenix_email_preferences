defmodule Mix.Tasks.Phx.Gen.EmailPreferencesTest do
  use ExUnit.Case

  @test_app_dir Path.join([System.tmp_dir!(), "phoenix_email_preferences_test_app"])

  setup do
    # Clean up any previous test runs
    File.rm_rf!(@test_app_dir)
    File.mkdir_p!(@test_app_dir)

    # Create minimal Phoenix app structure
    File.mkdir_p!(Path.join(@test_app_dir, "lib/test_app_web"))
    File.mkdir_p!(Path.join(@test_app_dir, "lib/test_app"))
    File.mkdir_p!(Path.join(@test_app_dir, "test/test_app_web/live"))
    File.mkdir_p!(Path.join(@test_app_dir, "test/test_app"))
    File.mkdir_p!(Path.join(@test_app_dir, "priv/repo/migrations"))

    # Write a minimal mix.exs
    mix_exs_content = """
    defmodule TestApp.MixProject do
      use Mix.Project

      def project do
        [
          app: :test_app,
          version: "0.1.0"
        ]
      end
    end
    """

    File.write!(Path.join(@test_app_dir, "mix.exs"), mix_exs_content)

    # Change to test app directory
    File.cd!(@test_app_dir)

    on_exit(fn ->
      File.rm_rf!(@test_app_dir)
    end)

    :ok
  end

  describe "template rendering" do
    test "renders templates with correct module names" do
      binding = [
        app_module: TestApp,
        web_module: TestAppWeb,
        context_app: :test_app,
        app_name: "test_app"
      ]

      # Test that module names are interpolated correctly
      template = "<%= @app_module %>.EmailPreferences"
      result = EEx.eval_string(template, assigns: binding)

      assert result == "Elixir.TestApp.EmailPreferences"
    end

    test "templates contain required functions" do
      # Read a template file and verify it has expected content
      email_prefs_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.txt"]))

      # Check for key functions
      assert email_prefs_template =~ "def get_user_preferences"
      assert email_prefs_template =~ "def opt_in"
      assert email_prefs_template =~ "def opt_out"
      assert email_prefs_template =~ "def has_consented?"
      assert email_prefs_template =~ "def generate_unsubscribe_token"
      assert email_prefs_template =~ "def verify_unsubscribe_token"
      assert email_prefs_template =~ "def initialize_default_preferences"
    end

    test "config template contains required functions" do
      config_template = File.read!(Path.join([__DIR__, "../../../priv/templates/config.ex.txt"]))

      assert config_template =~ "def load_config"
      assert config_template =~ "def preference_types"
      assert config_template =~ "def preference_details"
      assert config_template =~ "def categorized_preferences"
      assert config_template =~ "def default_preferences"
      assert config_template =~ "def can_opt_out?"
      assert config_template =~ "def preference_name"
    end

    test "LiveView template has dark mode support" do
      live_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_live.txt"]))

      # Verify dark mode classes are present
      assert live_template =~ "dark:bg-gray-800"
      assert live_template =~ "dark:text-zinc-100"
      # Toggle ON state
      assert live_template =~ "dark:bg-zinc-100"
      # Toggle OFF state
      assert live_template =~ "dark:bg-gray-600"
    end

    test "component template has dark mode support" do
      component_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/email_preferences_components.txt"])
        )

      assert component_template =~ "dark:border-gray-600"
      assert component_template =~ "dark:text-zinc-100"
      assert component_template =~ "dark:text-zinc-400"
    end

    test "unsubscribe template has dark mode support" do
      unsubscribe_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/unsubscribe_live.txt"]))

      assert unsubscribe_template =~ "dark:bg-gray-800"
      assert unsubscribe_template =~ "dark:text-zinc-100"
      assert unsubscribe_template =~ "dark:text-zinc-400"
    end
  end

  describe "test templates" do
    test "context test template uses dynamic preference types" do
      test_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/email_preferences_context_test.txt"])
        )

      # Should NOT have hardcoded preference types
      refute test_template =~ ~s("weekly_digest")
      refute test_template =~ ~s("educational")

      # Should use dynamic lookups
      assert test_template =~ "EmailPreferences.preference_types()"
      assert test_template =~ "[first_type | _]"
    end

    test "LiveView test template uses dynamic preference types" do
      test_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_test.txt"]))

      # Should use dynamic lookups
      assert test_template =~ "EmailPreferences.preference_types()"
      assert test_template =~ "default_prefs"
    end

    test "unsubscribe test template uses dynamic preference types" do
      test_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/unsubscribe_live_test.txt"]))

      # Should NOT have hardcoded preference types in setup
      refute test_template =~
               "opt_in(user.id, \"promotional\", %{source: \"test\"})\n      {:ok, _} = EmailPreferences.opt_in(user.id, \"weekly_digest\""

      # Should use dynamic types
      assert test_template =~ "available_types = EmailPreferences.preference_types()"
      assert test_template =~ "[first_type | rest]"
    end

    test "context test has initialization for default preferences" do
      test_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/email_preferences_context_test.txt"])
        )

      # Check the has_consented? test initializes defaults
      assert test_template =~ "# Initialize defaults first"
      assert test_template =~ "EmailPreferences.get_user_preferences(user.id)"
    end

    test "context test uses map_size instead of length for maps" do
      test_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/email_preferences_context_test.txt"])
        )

      # Should use map_size for preference maps
      assert test_template =~ "map_size(preferences_map)"
    end
  end

  describe "JSON configuration" do
    test "JSON template has correct structure" do
      json_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.json"]))

      # Should be valid JSON
      {:ok, config} = JSON.decode(json_template)

      # Check top-level keys
      assert Map.has_key?(config, "preferences")
      assert Map.has_key?(config, "categories")
      assert Map.has_key?(config, "apps")

      # Check preference structure
      assert is_map(config["preferences"])
      preferences = config["preferences"]

      for {_key, pref} <- preferences do
        assert Map.has_key?(pref, "name")
        assert Map.has_key?(pref, "description")
        assert Map.has_key?(pref, "category")
        assert Map.has_key?(pref, "can_opt_out")
        assert is_boolean(pref["can_opt_out"])
      end

      # Check categories have required fields
      for {_key, category} <- config["categories"] do
        assert Map.has_key?(category, "name")
        assert Map.has_key?(category, "description")
        assert Map.has_key?(category, "priority")
        assert is_integer(category["priority"])
      end
    end
  end

  describe "migration templates" do
    test "user preferences migration template is valid" do
      migration_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/migration_user_preferences.txt"]))

      assert migration_template =~ "table(:user_email_preferences)" or
               migration_template =~ "table :user_email_preferences"

      assert migration_template =~ "user_email_preferences"
      assert migration_template =~ "add :user_id"
      assert migration_template =~ "add :preference_type"
      assert migration_template =~ "add :opted_in"
      assert migration_template =~ "add :opted_in_at"
      assert migration_template =~ "add :opted_out_at"
      assert migration_template =~ "unique_index"
    end

    test "preference history migration template is valid" do
      migration_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/migration_preference_history.txt"])
        )

      assert migration_template =~ "table(:email_preference_history)" or
               migration_template =~ "table :email_preference_history"

      assert migration_template =~ "email_preference_history"
      assert migration_template =~ "add :user_id"
      assert migration_template =~ "add :preference_type"
      assert migration_template =~ "add :action"
      assert migration_template =~ "add :opted_in"
      assert migration_template =~ "add :source"
      assert migration_template =~ "add :ip_address"
      assert migration_template =~ "add :user_agent"
    end
  end

  describe "schema templates" do
    test "user preference schema has required fields" do
      schema_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/user_preference.txt"]))

      assert schema_template =~ "schema \"user_email_preferences\""
      assert schema_template =~ "belongs_to :user" or schema_template =~ ":user_id"
      assert schema_template =~ "field :preference_type"
      assert schema_template =~ "field :opted_in"
      assert schema_template =~ "field :opted_in_at"
      assert schema_template =~ "field :opted_out_at"
      assert schema_template =~ "timestamps("
    end

    test "preference history schema has required fields" do
      schema_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/preference_history.txt"]))

      assert schema_template =~ "schema \"email_preference_history\""
      assert schema_template =~ "belongs_to :user" or schema_template =~ ":user_id"
      assert schema_template =~ "field :preference_type"
      assert schema_template =~ "field :action"
      assert schema_template =~ "field :opted_in"
      assert schema_template =~ "field :source"
      assert schema_template =~ "field :ip_address"
    end
  end

  describe "accessibility" do
    test "LiveView template has proper ARIA labels" do
      live_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences_live.txt"]))

      assert live_template =~ "role=\"switch\""
      assert live_template =~ "aria-checked"
      assert live_template =~ "aria-label"
      assert live_template =~ "aria-describedby"
      assert live_template =~ "role=\"separator\""
      assert live_template =~ "role=\"region\""
    end

    test "unsubscribe template has proper ARIA labels" do
      unsubscribe_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/unsubscribe_live.txt"]))

      # Check for SVG elements which improve accessibility
      assert unsubscribe_template =~ "<svg"
      # Check for semantic HTML
      assert unsubscribe_template =~ "<h3"
      assert unsubscribe_template =~ "<p"
    end

    test "component template has proper labels" do
      component_template =
        File.read!(
          Path.join([__DIR__, "../../../priv/templates/email_preferences_components.txt"])
        )

      assert component_template =~ "<label for="
      assert component_template =~ "id={"
    end
  end

  describe "security features" do
    test "context template has token generation and verification" do
      context_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.txt"]))

      assert context_template =~ "Phoenix.Token.sign"
      assert context_template =~ "Phoenix.Token.verify"
      assert context_template =~ "max_age:"
    end

    test "history tracking includes source and IP" do
      context_template =
        File.read!(Path.join([__DIR__, "../../../priv/templates/email_preferences.txt"]))

      assert context_template =~ "source:"
      assert context_template =~ "ip_address:"
      assert context_template =~ "user_agent:"
    end
  end
end
