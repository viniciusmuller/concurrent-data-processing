defmodule PageProducer do
  use GenStage
  require Logger

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def scrape_pages(pages) when is_list(pages) do
    GenStage.cast(__MODULE__, {:pages, pages})
  end

  def init(initial_state) do
    Logger.info("PageProducer init")
    {:producer, initial_state}
  end

  def handle_demand(demand, state) do
    Logger.info("PageProducer received demand for #{demand} pages")
    events = []
    {:noreply, events, state}
  end

  def handle_cast({:pages, pages}, state) do
    Logger.info("PageProducer received pages: #{inspect(pages)}")
    # Produce pages (will be send to consumers)
    {:noreply, pages, state}
  end
end
