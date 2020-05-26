defmodule Brains.ModelBase do
  @moduledoc """
  This module helps to build quick and concise API model definitions.

  Example:

      defmodule Pet do
        use Brains.ModelBase
        field(:id)
        field(:category, as: Category)
        field(:tags, as: Tag, type: :list)
      end
  """
  require Poison.Decode

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      @fields []

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defstruct Keyword.keys(@fields)

      @doc """
      Unwrap a decoded JSON object into its complex fields.
      """
      @spec decode(struct(), keyword()) :: struct()
      def decode(value, _options) do
        Enum.reduce(@fields, value, fn {field_name, opts}, v ->
          if struct = Keyword.get(opts, :as) do
            Map.update!(v, field_name, fn current ->
              type = Keyword.get(opts, :type, :primitive)
              struct = Keyword.get(opts, :as)
              Brains.ModelBase.decode(current, type, struct)
            end)
          else
            v
          end
        end)
      end
    end
  end

  defmacro field(field_name, opts \\ []) do
    quote do
      @fields [{unquote(field_name), unquote(opts)} | @fields]
    end
  end

  @doc """
  Helper to decode model fields
  """
  @spec decode(struct(), :list | :map | :primitive, nil | module()) :: struct()
  def decode(nil, _, _) do
    nil
  end

  def decode(value, _, nil) do
    value
  end

  def decode(value, :list, DateTime) do
    Enum.map(value, &parse_date_time/1)
  end

  def decode(value, _, DateTime) do
    parse_date_time(value)
  end

  def decode(value, :list, Date) do
    Enum.map(value, &parse_date/1)
  end

  def decode(value, _, Date) do
    parse_date(value)
  end

  def decode(value, :map, module) when not is_nil(value) do
    value
    |> Enum.map(fn {k, v} ->
      {k, poison_transform(v, %{as: struct(module)})}
    end)
    |> Enum.into(%{})
  end

  def decode(value, :list, module) do
    poison_transform(value, %{as: [struct(module)]})
  end

  def decode(value, _, module) do
    poison_transform(value, %{as: struct(module)})
  end

  if function_exported?(Poison.Decode, :decode, 2) do
    def poison_transform(value, options) do
      Poison.Decode.decode(value, options)
    end
  else
    # Short-circuit if the value has already been transformed.
    # This works around a bug in poison 4 where Poison.decode does an extra
    # transformation pass on sub-structs.
    def poison_transform(%{__struct__: _} = value, %{as: _}) do
      value
    end

    def poison_transform([%{__struct__: _} | _] = value, %{as: [_]}) do
      value
    end

    def poison_transform(value, options) do
      Poison.Decode.transform(value, options)
    end
  end

  @doc """
  Helper to encode model into JSON
  """
  @spec encode(struct(), map()) :: String.t()
  def encode(value, options) do
    value
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> v != nil end)
    |> Enum.into(%{})
    |> Poison.Encoder.encode(options)
  end

  defp parse_date(nil), do: nil

  defp parse_date(%Date{} = date), do: date

  defp parse_date(ymd) do
    case Date.from_iso8601(ymd) do
      {:ok, date} -> date
      _ -> ymd
    end
  end

  defp parse_date_time(nil), do: nil

  defp parse_date_time(%DateTime{} = date_time), do: date_time

  defp parse_date_time(nanoseconds) when is_integer(nanoseconds) do
    case DateTime.from_unix(nanoseconds, :nanosecond) do
      {:ok, datetime} ->
        case datetime do
          %{year: year} when year > 2000 -> datetime
          _ -> parse_date_time(nanoseconds * 1000)
        end

      _ ->
        nanoseconds
    end
  end

  defp parse_date_time(iso8601) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, datetime, _offset} -> datetime
      {:error, :missing_offset} -> parse_date_time(iso8601 <> "Z")
      _ -> iso8601
    end
  end
end
