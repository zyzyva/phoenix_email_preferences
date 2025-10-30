defmodule <%= @web_module %>.EmailPreferencesLive do
  use <%= @web_module %>, :live_view

  alias <%= @app_module %>.EmailPreferences

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    preferences = load_preferences(user_id)

    {:ok,
     socket
     |> assign(:preferences, preferences)
     |> assign(:saving, false)}
  end

  @impl true
  def handle_event("toggle_preference", %{"type" => type}, socket) do
    user_id = socket.assigns.current_user.id
    current_preference = Enum.find(socket.assigns.preferences, &(&1.preference_type == type))

    result = if current_preference && current_preference.opted_in do
      EmailPreferences.opt_out(user_id, type, %{
        source: "preferences_page",
        ip_address: get_connect_info(socket, :peer_data) |> get_ip_address(),
        user_agent: get_connect_info(socket, :user_agent)
      })
    else
      EmailPreferences.opt_in(user_id, type, %{
        source: "preferences_page",
        ip_address: get_connect_info(socket, :peer_data) |> get_ip_address(),
        user_agent: get_connect_info(socket, :user_agent)
      })
    end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:preferences, load_preferences(user_id))
         |> put_flash(:info, "Preferences updated successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update preferences")}
    end
  end

  @impl true
  def handle_event("unsubscribe_all", _params, socket) do
    user_id = socket.assigns.current_user.id

    Enum.each(EmailPreferences.preference_types(), fn type ->
      EmailPreferences.opt_out(user_id, type, %{
        source: "preferences_page",
        ip_address: get_connect_info(socket, :peer_data) |> get_ip_address(),
        user_agent: get_connect_info(socket, :user_agent)
      })
    end)

    {:noreply,
     socket
     |> assign(:preferences, load_preferences(user_id))
     |> put_flash(:info, "Unsubscribed from all marketing emails")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Email Preferences
        <:subtitle>Manage which emails you receive from us</:subtitle>
      </.header>

      <div class="mt-8 space-y-6">
        <div class="bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <div class="space-y-6">
              <%= for pref <- @preferences do %>
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <h3 class="text-sm font-medium text-zinc-900">
                      <%= humanize_preference_type(pref.preference_type) %>
                    </h3>
                    <p class="mt-1 text-sm text-zinc-600">
                      <%= preference_description(pref.preference_type) %>
                    </p>
                    <p :if={pref.opted_in && pref.opted_in_at} class="mt-1 text-xs text-zinc-500">
                      Subscribed <%= format_date(pref.opted_in_at) %>
                    </p>
                    <p :if={!pref.opted_in && pref.opted_out_at} class="mt-1 text-xs text-zinc-500">
                      Unsubscribed <%= format_date(pref.opted_out_at) %>
                    </p>
                  </div>

                  <button
                    type="button"
                    phx-click="toggle_preference"
                    phx-value-type={pref.preference_type}
                    disabled={@saving}
                    class={[
                      "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:ring-offset-2",
                      if(pref.opted_in, do: "bg-zinc-900", else: "bg-gray-200")
                    ]}
                  >
                    <span class="sr-only">Toggle <%= pref.preference_type %></span>
                    <span class={[
                      "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                      if(pref.opted_in, do: "translate-x-5", else: "translate-x-0")
                    ]}>
                    </span>
                  </button>
                </div>

                <div :if={pref != List.last(@preferences)} class="border-t border-gray-200"></div>
              <% end %>
            </div>

            <div class="mt-6 border-t border-gray-200 pt-6">
              <button
                type="button"
                phx-click="unsubscribe_all"
                data-confirm="Are you sure you want to unsubscribe from all marketing emails?"
                disabled={@saving}
                class="text-sm text-red-600 hover:text-red-800"
              >
                Unsubscribe from all marketing emails
              </button>
            </div>
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm text-blue-700">
                You will continue to receive important account-related emails regardless of these preferences.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_preferences(user_id) do
    existing = EmailPreferences.get_user_preferences(user_id)
    existing_types = Enum.map(existing, & &1.preference_type)

    # Create default records for missing types
    Enum.map(EmailPreferences.preference_types(), fn type ->
      case Enum.find(existing, &(&1.preference_type == type)) do
        nil ->
          %{
            preference_type: type,
            opted_in: false,
            opted_in_at: nil,
            opted_out_at: nil
          }

        pref ->
          pref
      end
    end)
  end

  defp humanize_preference_type("marketing"), do: "Marketing emails"
  defp humanize_preference_type("newsletter"), do: "Newsletter"
  defp humanize_preference_type("product_updates"), do: "Product updates"
  defp humanize_preference_type("tips"), do: "Tips and tutorials"
  defp humanize_preference_type(type), do: Phoenix.Naming.humanize(type)

  defp preference_description("marketing"), do: "Product updates, special offers, and company news"
  defp preference_description("newsletter"), do: "Monthly newsletter with tips and best practices"
  defp preference_description("product_updates"), do: "New features and product announcements"
  defp preference_description("tips"), do: "Tips and tricks to get the most out of the product"
  defp preference_description(_), do: ""

  defp format_date(nil), do: ""
  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp get_ip_address(nil), do: nil
  defp get_ip_address({ip, _port}), do: :inet.ntoa(ip) |> to_string()
end
