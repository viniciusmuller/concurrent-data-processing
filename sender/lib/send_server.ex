defmodule SendServer do
  use GenServer

  @impl true
  def init(args) do
    max_retries = Keyword.get(args, :max_retries, 5)
    state = %{emails: [], max_retries: max_retries}
    Process.send_after(self(), :retry, 5_000)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:send, email}, state) do
    status = send_email(email)
    emails = [%{email: email, status: status, retries: 0} | state.emails]
    {:noreply, %{state | emails: emails}}
  end

  @impl true
  def handle_info(:retry, state) do
    {failed, done} =
      Enum.split_with(state.emails, fn item ->
        item.status == :failed and item.retries < state.max_retries
      end)

    retried =
      Enum.map(failed, fn item ->
        IO.puts("Retrying email #{item.email}")
        new_status = send_email(item.email)
        %{email: item.email, status: new_status, retries: item.retries + 1}
      end)

    Process.send_after(self(), :retry, 5_000)
    {:noreply, %{state | emails: retried ++ done}}
  end

  @impl true
  def terminate(reason, _state) do
    IO.puts "#{inspect(self())} terminating. reason: #{reason}"
  end

  defp send_email(email) do 
    case Sender.send_email(email) do
      :ok -> :sent
      :error -> :failed
    end
  end
end
