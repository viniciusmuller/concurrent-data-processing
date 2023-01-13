defmodule PageConsumerSupervised do
  require Logger

  def start_link(event) do
    Logger.info("PageConsumer #{inspect(self())} consumed #{inspect(event)}")

    Task.start(fn ->
      Scraper.work()
    end)
  end
end

defmodule PageConsumer do
  use GenStage
  require Logger

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(initial_state) do
    Logger.info("PageConsumer init")
    sub_options = [{PageProducer, min_demand: 0, max_demand: 1}]
    {:consumer, initial_state, subscribe_to: sub_options}
  end

  def handle_events(events, _from, state) do
    Logger.info("PageConsumer received #{inspect(events)}")

    Enum.each(events, fn _page ->
      Task.start(fn ->
        Scraper.work()
        IO.puts("work done")
      end)
    end)

    {:noreply, [], state}
  end
end
