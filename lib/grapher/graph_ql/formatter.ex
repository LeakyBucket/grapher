defmodule Grapher.GraphQL.Formatter do
  @moduledoc """
  The GraphQL Formatter module is responsible for handling translation from GraphQL's camelCase to Elixir snake_case and vice versa.
  """

  @doc """
  Converts the keys in a given map to `snake_case`.  This is useful when dealing with a raw GraphQL request so your eyes don't start to bleed.

  ## Parameters

    - `map`: The map which sould have it's keys converted

  ## Examples

      iex> Formatter.to_elixir(%{"userId" => "bob", "name" => "Uncle Bob"})
      %{user_id: "bob", name: "Uncle Bob"}

      iex> Formatter.to_elixir(%{"userId" => "bob", "profile" => %{"personalSummary" => "Buy my crap"}})
      %{user_id: "bob", profile: %{personal_summary: "Buy my crap"}}

      iex> Formatter.to_elixir([%{"locations" => [%{"column" => 0, "line" => 2}], "message" => "The specified user does not have a profile", "path" => ["updateProfile"]}])
      [%{locations: [%{column: 0, line: 2}], message: "The specified user does not have a profile", path: ["updateProfile"]}]

  """
  @spec to_elixir(map | list) :: map | list
  def to_elixir(%{} = response) do
    to_snake(response)
  end
  def to_elixir(response) when is_list(response) do
    Enum.map(response, fn
      element when is_binary(element) ->
        element
      element ->
        to_snake(element)
    end)
  end

  defp to_snake(map) do
    Enum.reduce(map, %{}, fn {key, value}, converted ->
      case value do
        %{} = value ->
          Map.put(converted, underscore(key), to_snake(value))
        value when is_list(value) ->
          Map.put(converted, underscore(key), to_elixir(value))
        _ ->
          Map.put(converted, underscore(key), value)
      end
    end)
  end

  defp underscore(key) do
    key
    |> Macro.underscore()
    |> String.to_atom()
  end

  @doc """
  Converts keys in a given map to `camelCase` mostly because JavaScript hates readability in general and specifically with variable names.

  ## Parameters

    - `map`: the map which should have it's keys converted

  ## Examples

      iex> Formatter.to_graph_ql(%{user_id: "bob", name: "Uncle Bob"})
      %{"userId" => "bob", "name" => "Uncle Bob"}

      iex> Formatter.to_graph_ql(%{user_id: "bob", profile: %{personal_summary: "Buy my crap"}})
      %{"userId" => "bob", "profile" => %{"personalSummary" => "Buy my crap"}}

  """
  @spec to_graph_ql(nil | map) :: map
  def to_graph_ql(nil), do: nil
  def to_graph_ql(%{} = payload) do
    to_camel(payload)
  end

  defp to_camel(map) do
    Enum.reduce(map, %{}, fn {key, value}, converted ->
      case value do
        %{} = value ->
          Map.put(converted, camelize(key), to_camel(value))
        _ ->
          Map.put(converted, camelize(key), value)
      end
    end)
  end

  defp camelize(key) when is_binary(key) do
    key
    |> String.split("_")
    |> case do
      [singleton] ->
        singleton
      [first | rest] ->
        first <> capitalize_tail(rest)
    end
  end
  defp camelize(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.scan(&(&2 <> String.capitalize(&1)))
    |> List.last()
  end

  defp capitalize_tail(tail) do
    Enum.reduce(tail, "", fn part, result ->
      result <> String.capitalize(part)
    end)
  end
end
