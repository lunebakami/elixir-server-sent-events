defmodule SseDemo.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SseDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:sse_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SseDemo.PubSub},
      # Start a worker by calling: SseDemo.Worker.start_link(arg)
      # {SseDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      SseDemoWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SseDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SseDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
