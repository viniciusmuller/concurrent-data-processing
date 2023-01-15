
Benchee.run(%{
  "airports_read_enum"    => fn -> Airports.open_airports_read_enum() end,
  "airports_stream_nocopy"    => fn -> Airports.open_airports_stream_nocopy() end,
  "airports_stream_copy"    => fn -> Airports.open_airports_stream_copy() end,
  "airports_flow_nimble_bottleneck"    => fn -> Airports.open_airports_flow_bottleneck() end,
  "airports_flow"    => fn -> Airports.open_airports_flow() end,
})
