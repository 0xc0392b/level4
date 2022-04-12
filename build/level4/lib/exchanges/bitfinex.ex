defmodule Exchanges.Bitfinex.Trading do
  @moduledoc """
  Translation scheme for the Bitfinex websocket API.

  Change log and websocket docs:
  - https://docs.bitfinex.com/docs/changelog
  - https://docs.bitfinex.com/docs/ws-general
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"book_cid" => nil, "trades_cid" => nil}
  end

  @impl TranslationScheme
  def ping_msg(current_state) do
    book =
      if current_state["book_cid"] != nil do
        {:ok, json_str_book} =
          Jason.encode(%{
            "event" => "ping",
            "cid" => current_state["book_cid"]
          })

        [json_str_book]
      else
        []
      end

    trade =
      if current_state["trades_cid"] != nil do
        {:ok, json_str_trade} =
          Jason.encode(%{
            "event" => "ping",
            "cid" => current_state["trades_cid"]
          })

        [json_str_trade]
      else
        []
      end

    {:ok, book ++ trade}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "book",
        "symbol" => "t#{base_symbol}#{quote_symbol}"
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "trades",
        "symbol" => "t#{base_symbol}#{quote_symbol}"
      })

    {:ok, [json_str_book, json_str_trade]}
  end

  @impl TranslationScheme
  def synchronised?(current_state) do
    # TODO
    true
  end

  @impl TranslationScheme
  def translate(json, current_state) do
    {instructions, next_state} =
      case json do
        [_, "hb"] ->
          {[:noop], current_state}

        %{"event" => "info"} ->
          {[:noop], current_state}

        %{"event" => "conf"} ->
          {[:noop], current_state}

        %{"event" => "pong"} ->
          {[:noop], current_state}

        %{"event" => "subscribed", "channel" => "book", "chanId" => chan_id} ->
          {[:noop], %{current_state | "book_cid" => chan_id}}

        %{"event" => "subscribed", "channel" => "trades", "chanId" => chan_id} ->
          {[:noop], %{current_state | "trades_cid" => chan_id}}

        [chan_id, data] ->
          cond do
            chan_id == current_state["book_cid"] ->
              case data do
                [price_int, count, amount_int] ->
                  price = price_int / 1
                  amount = amount_int / 1

                  delta =
                    cond do
                      amount > 0 ->
                        if count == 0 do
                          {:bid, price, 0}
                        else
                          {:bid, price, amount}
                        end

                      amount <= 0 ->
                        if count == 0 do
                          {:ask, price, 0}
                        else
                          {:ask, price, -amount}
                        end
                    end

                  {[{:deltas, [delta]}], current_state}

                levels ->
                  bids =
                    levels
                    |> Enum.filter(fn [_, _, amount] -> amount > 0 end)
                    |> Enum.map(fn [price_int, _, amount_int] ->
                      price = price_int / 1
                      amount = amount_int / 1
                      {price, amount}
                    end)

                  asks =
                    levels
                    |> Enum.filter(fn [_, _, amount] -> amount <= 0 end)
                    |> Enum.map(fn [price_int, _, amount_int] ->
                      price = price_int / 1
                      amount = amount_int / 1
                      {price, -amount}
                    end)

                  {[{:snapshot, bids, asks}], current_state}
              end

            chan_id == current_state["trades_cid"] ->
              {[:noop], current_state}
          end

        [chan_id, _, data] ->
          cond do
            chan_id == current_state["trades_cid"] ->
              [_, epoch_ms, amount_int, price_int] = data

              price = price_int / 1
              amount = amount_int / 1

              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              if amount > 0 do
                {[{:buys, [{price, amount, timestamp}]}], current_state}
              else
                {[{:sells, [{price, -amount, timestamp}]}], current_state}
              end
          end
      end

    {:ok, instructions, next_state}
  end
end
