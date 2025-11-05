defmodule Mix.Tasks.Phx.Gen.EmailPreferences.Remove.MigrationRollback do
  @moduledoc """
  Handles rolling back email preferences migrations.
  """

  @doc """
  Checks if the given migrations have been applied.
  """
  def migrations_applied?(migration_files) do
    versions = extract_versions(migration_files)

    if Enum.empty?(versions) do
      false
    else
      query = """
      SELECT version FROM schema_migrations
      WHERE version = ANY($1::bigint[])
      """

      case Ecto.Adapters.SQL.query(get_repo(), query, [versions]) do
        {:ok, %{rows: [_ | _]}} -> true
        _ -> false
      end
    end
  end

  @doc """
  Rolls back the given migration files.
  """
  def rollback(migration_files) do
    repo = get_repo()

    migration_files
    |> Enum.sort(:desc)
    |> Enum.each(fn file ->
      version = extract_version(file)

      case run_migration_down(repo, file, version) do
        :ok ->
          Mix.shell().info([:green, "Successfully rolled back ", :reset, Path.basename(file)])

        {:error, reason} ->
          Mix.shell().error([
            :red,
            "Failed to rollback ",
            :reset,
            Path.basename(file),
            ": #{inspect(reason)}"
          ])
      end
    end)
  end

  defp run_migration_down(repo, file, version) do
    # Load the migration module
    [{module, _}] = Code.require_file(file)

    # Run the down migration using Ecto.Migrator.run/4
    opts = [all: false, log: :info]

    case Ecto.Migrator.run(repo, [{version, module}], :down, opts) do
      [{:ok, _version, _}] -> :ok
      [{:error, reason, _}] -> {:error, reason}
      _ -> :ok
    end
  rescue
    e -> {:error, e}
  end

  defp extract_versions(migration_files) do
    Enum.map(migration_files, &extract_version/1)
  end

  defp extract_version(file) do
    file
    |> Path.basename()
    |> String.split("_")
    |> hd()
    |> String.to_integer()
  end

  defp get_repo do
    # Get the configured Ecto repo for the current application
    context_app = Mix.Phoenix.context_app()

    case Application.get_env(context_app, :ecto_repos) do
      [repo | _] ->
        repo

      _ ->
        Mix.raise("""
        Could not find an Ecto repo configured for #{context_app}.

        Please configure your repo in config/config.exs:

            config #{inspect(context_app)},
              ecto_repos: [#{Macro.camelize(Atom.to_string(context_app))}.Repo]
        """)
    end
  end
end
