defmodule BookingsPipeline do
  use Broadway

  require Logger

  @producer BroadwayRabbitMQ.Producer

  @producer_config [
    queue: "bookings_queue",
    declare: [durable: true],
    on_failure: :reject_and_requeue
  ]

  def start_link(_args) do
    options = [
      name: BookingsPipeline,
      producer: [module: {@producer, @producer_config}],
      processors: [
        default: []
      ],
      batchers: [
        play: [concurrency: 100],
        musical: [concurrency: 100],
        default: [concurrency: 100]
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  def handle_message(_processor, message, _context) do
    event = message.data.event

    if Tickets.tickets_available?(event) do
      case event do
        "play" ->
          Broadway.Message.put_batcher(message, :play)

        "musical" ->
          Broadway.Message.put_batcher(message, :musical)

        _ ->
          message
      end
    else
      Broadway.Message.failed(message, "bookings-closed")
    end
  end

  def prepare_messages(messages, _context) do
    messages =
      Enum.map(messages, fn message ->
        Broadway.Message.update_data(message, fn data ->
          [event, user_id] = String.split(data, ",")
          %{event: event, user_id: user_id}
        end)
      end)

    users = Tickets.user_by_ids(Enum.map(messages, & &1.data.user_id))

    Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        user = Enum.find(users, &(&1.id == data.user_id))
        Map.put(data, :user, user)
      end)
    end)
  end

  def handle_batch(_batcher, messages, batch_info, _context) do
    Logger.info("#{inspect(self())} Batch #{batch_info.batcher} #{batch_info.batch_key}")

    messages
    |> Tickets.insert_all_tickets()
    |> Enum.each(fn %{data: %{user: user}} = message ->
      channel = message.metadata.amqp_channel
      payload = "email,#{user.email}"
      AMQP.Basic.publish(channel, "", "notifications_queue", payload)
    end)

    messages
  end

  def handle_failed(messages, _context) do
    Enum.map(messages, fn
      %{status: {:failed, "bookings-closed"}} = message ->
        Broadway.Message.configure_ack(message, on_failure: :reject)

      message ->
        message
    end)
  end
end
