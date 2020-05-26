defmodule Brains.Connection do
  @moduledoc """
  Handle Tesla connections for `Brains` GraphQL client.
  """

  @type t :: Tesla.Env.client()

  @doc """
  Builds a base URL based on a given server spec.
  """
  def base_url(server_spec, default_port, default_scheme \\ "http")

  def base_url(<<"http://", _::binary>> = server_spec, _default_port, _default_scheme),
    do: server_spec

  def base_url(<<"https://", _::binary>> = server_spec, _default_port, _default_scheme),
    do: server_spec

  def base_url(server_spec, default_port, default_scheme) do
    if Regex.match?(~r{^[^:]+:[0-9]+}, server_spec) do
      "#{default_scheme}://#{server_spec}"
    else
      "#{default_scheme}://#{server_spec}:#{default_port}"
    end
  end

  @doc """
  Builds a Tesla client.
  """
  def new(base_url, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 15_000)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.DecompressResponse,
      {Tesla.Middleware.Timeout, timeout: timeout}
    ]

    middleware =
      case Keyword.take(opts, [:username, :password]) do
        [username: username, password: password] ->
          middleware ++
            [
              {Tesla.Middleware.BasicAuth, %{username: username, password: password}}
            ]

        _ ->
          middleware
      end

    Tesla.client(middleware)
  end

  @doc """
  Converts a Brains.Request struct into a keyword list to send via
  Tesla.
  """
  @spec build_request(Brains.Request.t()) :: keyword()
  def build_request(request) do
    [url: request.url, method: request.method]
    |> build_query(request.query)
    |> build_headers(request.header)
    |> build_body(request.body, request.file)
  end

  defp build_query(output, []), do: output

  defp build_query(output, query_params) do
    Keyword.put(output, :query, query_params)
  end

  @brains_version Mix.Project.config() |> Keyword.get(:version, "")

  defp build_headers(output, header_params) do
    api_client =
      Enum.join(
        [
          "elixir/#{System.version()}",
          "brains/#{@brains_version}"
        ],
        " "
      )

    headers = [{"user-agent", api_client} | header_params]
    Keyword.put(output, :headers, headers)
  end

  # If no body or file fields and the request is a POST, set an empty body
  defp build_body(output, [], []) do
    method = Keyword.fetch!(output, :method)
    set_default_body(output, method)
  end

  defp build_body(output, [body: main_body], []) do
    Keyword.put(output, :body, main_body)
  end

  defp build_body(output, [], file_params) do
    body =
      Enum.reduce(file_params, Tesla.Multipart.new(), fn {file_name, file_path}, b ->
        Tesla.Multipart.add_file(b, file_path, name: file_name)
      end)

    Keyword.put(output, :body, body)
  end

  defp build_body(output, body_params, file_params) do
    body = Tesla.Multipart.new()

    body =
      Enum.reduce(body_params, body, fn {body_name, data}, b ->
        Tesla.Multipart.add_field(
          b,
          body_name,
          Poison.encode!(data),
          headers: [{:"Content-Type", "application/json"}]
        )
      end)

    body =
      Enum.reduce(file_params, body, fn {file_name, file_path}, b ->
        Tesla.Multipart.add_file(b, file_path, name: file_name)
      end)

    Keyword.put(output, :body, body)
  end

  @required_body_methods [:post, :patch, :put, :delete]

  defp set_default_body(output, method) when method in @required_body_methods do
    Keyword.put(output, :body, "")
  end

  defp set_default_body(output, _) do
    output
  end

  @doc """
  Execute a request on this connection

  ## Returns

    * `{:ok, Tesla.Env.t}` - If the call was successful
    * `{:error, reason}` - If the call failed
  """
  @spec execute(Tesla.Client.t(), Brains.Request.t()) :: {:ok, Tesla.Env.t()}
  def execute(connection, request) do
    request
    |> build_request()
    |> (&Tesla.request(connection, &1)).()
  end
end
