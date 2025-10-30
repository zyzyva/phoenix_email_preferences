defmodule <%= @web_module %>.EmailPreferencesComponents do
  @moduledoc """
  Email preference components for forms and settings.
  """
  use Phoenix.Component

  attr :preference_type, :string, required: true
  attr :label, :string, default: nil
  attr :checked, :boolean, default: false
  attr :description, :string, default: nil
  attr :name, :string, default: nil
  attr :class, :string, default: nil

  def opt_in_checkbox(assigns) do
    assigns = assign_new(assigns, :label, fn ->
      humanize_preference_type(assigns.preference_type)
    end)

    assigns = assign_new(assigns, :name, fn ->
      "preferences[#{assigns.preference_type}]"
    end)

    ~H"""
    <div class={["flex items-start", @class]}>
      <div class="flex h-6 items-center">
        <input
          type="checkbox"
          name={@name}
          id={"preference_#{@preference_type}"}
          checked={@checked}
          value="true"
          class="h-4 w-4 rounded border-gray-300 text-zinc-900 focus:ring-zinc-900"
        />
      </div>
      <div class="ml-3">
        <label for={"preference_#{@preference_type}"} class="text-sm font-medium text-zinc-900">
          {@label}
        </label>
        <p :if={@description} class="text-sm text-zinc-600">
          {@description}
        </p>
      </div>
    </div>
    """
  end

  attr :preferences, :list, default: []
  attr :checked_types, :list, default: []

  def signup_preferences(assigns) do
    assigns = assign(assigns, :preference_descriptions, %{
      "marketing" => "Product updates, special offers, and company news",
      "newsletter" => "Monthly newsletter with tips and best practices",
      "product_updates" => "New features and product announcements",
      "tips" => "Tips and tricks to get the most out of the product"
    })

    ~H"""
    <div class="space-y-4">
      <div class="border-b border-gray-200 pb-2">
        <h3 class="text-base font-semibold text-zinc-900">Email Preferences</h3>
        <p class="mt-1 text-sm text-zinc-600">
          Choose which emails you'd like to receive from us.
        </p>
      </div>

      <div class="space-y-3">
        <.opt_in_checkbox
          :for={type <- @preferences}
          preference_type={type}
          checked={type in @checked_types}
          description={@preference_descriptions[type]}
        />
      </div>

      <p class="text-xs text-zinc-500">
        You can change these preferences at any time from your account settings.
      </p>
    </div>
    """
  end

  defp humanize_preference_type("marketing"), do: "Marketing emails"
  defp humanize_preference_type("newsletter"), do: "Newsletter"
  defp humanize_preference_type("product_updates"), do: "Product updates"
  defp humanize_preference_type("tips"), do: "Tips and tutorials"
  defp humanize_preference_type(type), do: Phoenix.Naming.humanize(type)
end
