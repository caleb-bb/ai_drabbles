defmodule AiDrabbles.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiDrabblesWeb.Telemetry,
      AiDrabbles.Repo,
      {DNSCluster, query: Application.get_env(:ai_drabbles, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AiDrabbles.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AiDrabbles.Finch},
      # Start a worker by calling: AiDrabbles.Worker.start_link(arg)
      # {AiDrabbles.Worker, arg},
      # Start to serve requests, typically the last entry
      AiDrabblesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiDrabbles.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiDrabblesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
