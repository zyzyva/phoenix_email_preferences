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

  alias Mix.Tasks.Phx.Gen.EmailPreferences.{
    TemplateLoader,
    FileGenerator,
    ShellInstructions
  }

  @impl Mix.Task
  def run(_args) do
    validate_project_structure!()

    context_app = Mix.Phoenix.context_app()
    web_prefix = Mix.Phoenix.web_path(context_app)
    context_lib_path = Mix.Phoenix.context_lib_path(context_app, "")

    binding = build_binding(context_app)

    validate_module_availability!(binding)

    templates = TemplateLoader.load_all()
    FileGenerator.generate_all(context_app, web_prefix, context_lib_path, binding, templates)
    ShellInstructions.print(binding)
  end

  defp validate_project_structure! do
    if Mix.Project.umbrella?() do
      Mix.raise("""
      mix phx.gen.email_preferences must be invoked from within your *_web
      application root directory
      """)
    end
  end

  defp build_binding(context_app) do
    base_module = Macro.camelize(Atom.to_string(context_app))

    [
      context_app: context_app,
      web_module: "#{base_module}Web",
      app_module: base_module,
      app_name: Atom.to_string(context_app)
    ]
  end

  defp validate_module_availability!(binding) do
    module_name = Module.concat([binding[:context_app], "EmailPreferences"])
    Mix.Phoenix.check_module_name_availability!(module_name)
  end
end
