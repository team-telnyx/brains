# Brains

Brains is a GraphQL client in Elixir.

The name derives from [Neuron](https://github.com/uesteibar/neuron). While
`Neuron` is based on `HTTPoison`, `Brains` is built on top of `Tesla`.

## Installation

```elixir
def deps do
  [
    {:brains, "~> 0.1"}
  ]
end
```

You can determine the latest version by running `mix hex.info brains` in your shell, or by going to the `brains` [page on Hex.pm](https://hex.pm/packages/brains).

## Documentation

Documentation can be found in [https://hexdocs.pm/brains](https://hexdocs.pm/brains).

## Usage

```elixir
iex> connection = Brains.Connection.new("https://example.com/graph")
iex> Brains.query(connection, """
    {
      films {
        title
      }
    }
    """
)
{:ok,
 %Tesla.Env{
   body: "{\"data\":{\"films\":[{\"title\":\"A New Hope\"}]}}",
   status: 200,
   headers: []
 }}
```

You can also run mutations:

```elixir
iex> Brains.query(connection, """
  mutation createUser($name: String!) {
    createUser(name: $name) {
      id
      name
    }
  }
  """,
  variables: %{name: "uesteibar"}
)
```

And if you need to pass custom headers (like authentication), do:

```elixir
iex> Brains.query(connection, """
  mutation createUser($name: String!) {
    createUser(name: $name) {
      id
      name
    }
  }
  """,
  variables: %{name: "uesteibar"},
  headers: [{"authorization", "Bearer <token>"}]
)
```

It is also possible to decode the body using `Poison` by using
`Brains.Response.decode/2`, this way:

```elixir
iex> connection = Brains.Connection.new("https://example.com/graph")
iex> Brains.query(connection, """
    {
      films {
        title
      }
    }
    """
) |> Brains.Response.decode()
{:ok,
 %Tesla.Env{
   body: %{
     "data" => %{
       "films" => [
         %{ "title" => "A New Hope" }
       ]
     }
   },
   status: 200,
   headers: []
 }}
```

The function `Brains.Response.decode/2` accepts the same `Poison.decode/2`
options, so if you prefer decoding as structs, use the option
[`:as`](https://hexdocs.pm/poison/Poison.html#module-usage).
