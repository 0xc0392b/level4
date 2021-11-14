defmodule Exchanges.Bitfinex do
  @moduledoc """
  Contains translation scheme for the Bitfinex websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    nil
  end

  @impl TranslationScheme
  def make_subscribe_message(major_symbol, quote_symbol) do
    nil
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    nil
  end
end
