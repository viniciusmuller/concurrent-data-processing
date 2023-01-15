defmodule Airports do
  @moduledoc """
  Documentation for `Airports`.
  """

  alias NimbleCSV.RFC4180, as: CSV

  def airports_csv() do
    Application.app_dir(:airports, "/priv/airports.csv")
  end

  def count_airports do
    airports_csv()
    |> File.stream!()
    |> Flow.from_enumerable()
    |> Flow.map(fn row ->
      [row] = CSV.parse_string(row, skip_headers: false)

      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8),
        city: Enum.at(row, 10)
      }
    end)
    |> Flow.reject(&(&1.type == "closed"))
    # do not repeat entries (and use the :country key for uniqueness)
    |> Flow.partition(key: {:key, :country})
    |> Flow.group_by(& &1.country)
    # TODO: use Flow.on_trigger/2
    |> Flow.map(fn {country, data} -> {country, Enum.count(data)} end)
    |> Flow.take_sort(10, fn {_, a}, {_, b} -> a > b end)
    |> Enum.to_list()
    |> List.flatten()
  end

  @doc """
  Here we are bottlenecking the Flow consumer by running `CSV.parse_stream()`
  """
  def open_airports_flow do
    airports_csv()
    |> File.stream!()
    |> Flow.from_enumerable()
    |> Flow.map(fn row ->
      [row] = CSV.parse_string(row, skip_headers: false)

      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8),
        city: Enum.at(row, 10)
      }
    end)
    |> Flow.reject(&(&1.type == "closed"))
    |> Enum.to_list()
  end

  @doc """
  Here we are bottlenecking the Flow consumer by running `CSV.parse_stream()`
  """
  def open_airports_flow_bottleneck do
    airports_csv()
    |> File.stream!()
    |> CSV.parse_stream()
    |> Flow.from_enumerable()
    |> Flow.map(fn row ->
      %{
        id: :binary.copy(Enum.at(row, 0)),
        type: :binary.copy(Enum.at(row, 2)),
        name: :binary.copy(Enum.at(row, 3)),
        country: :binary.copy(Enum.at(row, 8)),
        city: :binary.copy(Enum.at(row, 10))
      }
    end)
    |> Flow.reject(&(&1.type == "closed"))
    |> Enum.to_list()
  end

  @doc """
  Read https://hexdocs.pm/nimble_csv/NimbleCSV.html#module-binary-references 
  for more info
  """
  def open_airports_stream_copy do
    airports_csv()
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn row ->
      %{
        id: :binary.copy(Enum.at(row, 0)),
        type: :binary.copy(Enum.at(row, 2)),
        name: :binary.copy(Enum.at(row, 3)),
        country: :binary.copy(Enum.at(row, 8)),
        city: :binary.copy(Enum.at(row, 10))
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end

  def open_airports_stream_nocopy do
    airports_csv()
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn row ->
      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8),
        city: Enum.at(row, 10)
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end

  def open_airports_read_enum do
    airports_csv()
    |> File.read!()
    |> CSV.parse_string()
    |> Enum.map(fn row ->
      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8),
        city: Enum.at(row, 10)
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end
end
