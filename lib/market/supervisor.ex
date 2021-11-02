defmodule Market.Supervisor do
  @moduledoc """
  ...
  """

  use Supervisor

  @doc """
  ...
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  ...
  """
  @impl true
  def init(:ok) do
    Supervisor.init(
      [
        Market.Exchange,
        Market.Level2.Supervisor
      ],
      strategy: :one_for_all
    )
  end
end
