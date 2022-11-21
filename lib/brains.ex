defmodule Brains do
  @moduledoc """
  `Brains` is a GraphQL client for Elixir on top of `Tesla`.

  ## Usage

  ```elixir
  connection = Brains.Connection.new("https://example.com/graph")
  Brains.query(connection, \"""
      {
        films {
          title
        }
      }
      \"""
  )
  {:ok,
   %Tesla.Env{
     body: "{\\"data\\":{\\"films\\":[{\\"title\\":\\"A New Hope\\"}]}}",
     status: 200,
     headers: []
   }}
  ```

  You can also run mutations:

  ```elixir
  Brains.query(connection, \"""
    mutation createUser($name: String!) {
      createUser(name: $name) {
        id
        name
      }
    }
    \""",
    variables: %{name: "uesteibar"}
  )
  ```
  """

  alias Brains.{Connection, Request}

  @type connection :: Tesla.Client.t()

  @type query_string :: String.t()

  @type url :: String.t()

  @type headers :: [header]

  @type header :: {String.t(), String.t()}

  @type options :: [option]

  @type option ::
          {:operation_name, String.t()}
          | {:variables, map}
          | {:headers, headers}
          | {:url, url}

  @doc """
  Runs a query request to your graphql endpoint.

  ## Example

  ```elixir
  Brains.query(connection, \"""
    {
      films {
        count
      }
    }
  \""")
  ```

  You can also pass variables for your query:

  ```elixir
  Brains.query(connection, \"""
    mutation createUser($name: String!) {
      createUser(name: $name) {
        id
        name
      }
    }
    \""",
    variables: %{name: "uesteibar"}
  )
  ```
  """
  @spec query(
          connection,
          query_string :: map() | String.t(),
          options :: keyword()
        ) ::
          {:ok, map}
          | {:error, reason :: term}
  def query(connection, query_string, options \\ [])
      when is_binary(query_string) and is_list(options) do
    body = %{
      "query" => query_string
    }

    body =
      case Keyword.get(options, :operation_name) do
        nil -> body
        name -> Map.put(body, "operationName", name)
      end

    body =
      case Keyword.get(options, :variables) do
        nil -> body
        variables -> Map.put(body, "variables", variables)
      end

    request =
      Request.new()
      |> Request.method(:post)
      |> Request.add_param(:header, "content-type", "application/json")
      |> Request.add_param(:body, :body, body |> Poison.encode!())

    request =
      case Keyword.get(options, :headers) do
        nil ->
          request

        headers ->
          Enum.reduce(headers, request, fn {key, value}, req ->
            Request.add_param(req, :header, key, value)
          end)
      end

    request =
      case Keyword.get(options, :url) do
        nil ->
          request

        url ->
          Request.url(request, url)
      end

    connection
    |> Connection.execute(request)
  end
end
