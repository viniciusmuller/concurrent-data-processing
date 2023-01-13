defmodule Jobber.Job do
  use GenServer, restart: :transient
  require Logger

  defstruct [:work, :id, :max_retries, retries: 0, status: :new]

  def start_link(args) do
    id = Keyword.get(args, :id, random_job_id())
    args = Keyword.put(args, :id, id)
    type = Keyword.get(args, :type)
    GenServer.start_link(__MODULE__, args, name: via(id, type))
  end

  @impl true
  def init(args) do
    work = Keyword.fetch!(args, :work)
    id = Keyword.fetch!(args, :id)
    max_retries = Keyword.get(args, :max_retries, 3)

    state = %Jobber.Job{id: id, work: work, max_retries: max_retries}
    {:ok, state, {:continue, :run}}
  end

  @impl true
  def handle_continue(:run, state) do
    new_state = state.work.() |> handle_job_result(state)

    if new_state.status == :errored do
      Process.send_after(self(), :retry, 5_000)
      {:noreply, new_state}
    else
      Logger.info("Job #{state.id} exiting")
      {:stop, :normal, new_state}
    end
  end

  @impl true
  def handle_info(:retry, state) do
    {:noreply, state, {:continue, :run}}
  end

  defp handle_job_result({:ok, _data}, state) do
    Logger.info("Job #{state.id} completed")
    %Jobber.Job{state | status: :done}
  end

  defp handle_job_result({:error, reason}, %{status: :new} = state) do
    Logger.warn("Job #{state.id} errored: #{reason}")
    %Jobber.Job{state | status: :errored}
  end

  defp handle_job_result({:error, reason}, %{status: :errored} = state) do
    state = %Jobber.Job{state | retries: state.retries + 1}
    Logger.warn("Job #{state.id} retry #{state.retries} failed: #{reason}")

    if state.retries >= state.max_retries do
      %Jobber.Job{state | status: :failed}
    else
      state
    end
  end

  defp via(key, value) do
    {:via, Registry, {Jobber.JobRegistry, key, value}}
  end

  defp random_job_id do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
