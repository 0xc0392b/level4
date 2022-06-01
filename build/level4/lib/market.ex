defmodule Market do
  @moduledoc """
  Level4.Market encapsulates configuration for a particular market.
  Recall: a "market" is a tradeable currency pair on a specific exchange
  e.g. `COINBASE-PRO.SPOT:BTC-USD`. Level4.Market is essentially our
  internal, high-level representation of a single data feed.
  """

  # a market has an exchange name, a type, base and quote currency
  # symbols, and an exchange-specific translation scheme for communication
  # with its websocket API.
  @enforce_keys [
    :exchange_name,
    :market_type,
    :market_id,
    :ws_url,
    :ws_path,
    :ws_port,
    :base_symbol,
    :quote_symbol,
    :translation_scheme,
    :ping?
  ]
  defstruct [
    :exchange_name,
    :market_type,
    :market_id,
    :ws_url,
    :ws_path,
    :ws_port,
    :base_symbol,
    :quote_symbol,
    :translation_scheme,
    :ping?
  ]

  @doc """
  A market's tag is:

  <exchange name>.<market type>:<base>-<quote>

  Always fully capitalised. for example:
  - COINBASE-PRO.SPOT:BTC-USDT
  - POLONIEX.SPOT:BTC-USDT
  - POLONIEX.PERP:BTC-USDT
  """
  @spec tag(Market) :: String.t()
  def tag(market) do
    exchange_name = String.upcase(market.exchange_name)
    market_type = String.upcase(market.market_type)
    base_symbol = String.upcase(market.base_symbol)
    quote_symbol = String.upcase(market.quote_symbol)
    "#{exchange_name}.#{market_type}:#{base_symbol}-#{quote_symbol}"
  end
end

defimpl String.Chars, for: Market do
  def to_string(market) do
    Market.tag(market)
  end
end