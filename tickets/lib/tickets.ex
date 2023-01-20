defmodule Tickets do
  @moduledoc """
  Documentation for `Tickets`.
  """

  @users [
    %{id: "1", email: "foo@email.com"},
    %{id: "2", email: "bar@email.com"},
    %{id: "3", email: "baz@email.com"}
  ]

  def tickets_available?("cinema") do
    Process.sleep(Enum.random(100..200))
    false
  end

  def tickets_available?(_event) do
    Process.sleep(Enum.random(100..200))
    true
  end

  def create_ticket(_user, _event) do
    Process.sleep(Enum.random(250..1000))
  end

  def send_email(_user) do
    Process.sleep(Enum.random(100..250))
  end

  def user_by_ids(ids) when is_list(ids) do
    Enum.filter(@users, &(&1.id in ids))
  end

  def insert_all_tickets(messages) do
    Process.sleep(Enum.count(messages) * 10)
    messages
  end
end
