defmodule Sender do
  @moduledoc """
  Documentation for `Sender`.
  """

  @emails [
    "email1@example.com",
    "email2@example.com",
    "email3@example.com",
    "email4@example.com",
    "email5@example.com",
    "email6@example.com",
    "email7@example.com",
    "email8@example.com"
  ]

  @doc """
  Hello world.

  ## Examples

      iex> Sender.hello()
      :world

  """
  def hello do
    :world
  end

  def send_email("email3@example.com" = email) do
    raise "could not send email to #{email}"
  end

  # Slow email
  def send_email("email8@example.com") do
    Process.sleep(10_000)
    :ok
  end

  def send_email(destination) do
    Process.sleep(3_000)
    IO.puts("Email to #{destination} sent")
    :ok
  end

  def notify_all() do
    # runs at most 5 tasks of the list concurrently
    # we can disable ordering if we don't need it, so it won't wait for slower processes
    # NOTICE: If any of these tasks crash, the current process will also crash!!
    # |> Task.async_stream(&send_email/1, max_concurrency: 5, ordering: false)

    Sender.EmailTaskSupervisor
    |> Task.Supervisor.async_stream_nolink(@emails, &send_email/1, on_timeout: :kill_task)
    |> Stream.zip(@emails) # Label the emails, so we can know which ones crashed or timed out
    |> Enum.to_list()
  end
end
