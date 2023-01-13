defmodule PageConsumerSupervisor do
  use ConsumerSupervisor
  require Logger

  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.info("PageConsumerSupervisor initializing")

    children = [
      %{
        id: PageConsumer,
        start: {PageConsumerSupervised, :start_link, []},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [
        {OnlinePageProducerConsumer.via("online_page_producer_consumer_1"), []},
        {OnlinePageProducerConsumer.via("online_page_producer_consumer_2"), []},
      ]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end

