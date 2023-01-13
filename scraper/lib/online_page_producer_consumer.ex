defmodule OnlinePageProducerConsumer do
  @moduledoc """
  A producer-consumer receives a list of events, map them with operations and 
  then sends them to the next step when there's demand
  """

  use GenStage

  require Logger

  def start_link(id) do
    GenStage.start_link(__MODULE__, [], name: via(id))
  end

  def init(initial_state) do
    Logger.info("OnlinePageProducerConsumer init")

    subscription = [
      {PageProducer, min_demand: 0, max_demand: 1}
    ]

    {:producer_consumer, initial_state, subscribe_to: subscription}
  end

  def handle_events(events, _from, state) do
    Logger.info("OnlinePageProducer received #{inspect(events)}")
    events = Enum.filter(events, &Scraper.online?/1)
    {:noreply, events, state}
  end

  def via(id) do
    {:via, Registry, {ProducerConsumerRegistry, id}}
  end
end
