send_messages = fn n ->
  {:ok, connection} = AMQP.Connection.open()
  {:ok, channel} = AMQP.Channel.open(connection)

  Enum.each(1..n, fn _ ->
    event = Enum.random(["cinema", "musical", "play"])
    user_id = Enum.random(1..3)
    AMQP.Basic.publish(channel, "", "bookings_queue", "#{event},#{user_id}")
  end)

  AMQP.Connection.close(connection)
end
