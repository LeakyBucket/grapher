defmodule Grapher.SchemaContext do
  @moduledoc """
  Defines a GraphQL Schema context
  """

  defstruct [url: "", headers: []]
  @type t :: %__MODULE__{url: String.t, headers: Keyword.t}

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(__MODULE__), [:set, :named_table, :protected]

    :ok
  end

  @doc """
  Saves a new schema configuration with the given name.  This function will return `:context_already_configured` if there is already a context registered with the given name.

  ## Parameters

    - name: An atom that will be used to reference this Schema Configuration
    - context: A `__MODULE__.t` struct defining the Schema Configuration

  ## Examples

      iex> SchemaContext.add_schema(:auth, %SchemaContext{url: "www.com.com", headers: []})
      :ok

      iex> SchemaContext.add_schema(:auth, %SchemaContext{url: "www.com.com"})
      iex> SchemaContext.add_schema(:auth, %SchemaContext{url: "www.net.com"})
      :context_already_configured

  """
  @spec add_schema(atom, __MODULE__.t) :: :ok | :context_already_configured
  def add_schema(name, context) do
    GenServer.call(__MODULE__, {:add, %{name: name, context: context}})
  end

  @doc """
  Updates the schema definition with the given name.  This function will return `:no_such_context` if there is no context registered with the given name.

  ## Parameters

    - name: An atom representing the name of the schema to be updated
    - context: A `__MODULE__.t` struct defining the Schem Configuration that should replace the current configuration

  ## Examples

      iex> SchemaContext.add_schema(:update, %SchemaContext{url: "www.org.com"})
      iex> SchemaContext.update_schema(:update, %SchemaContext{url: "www.com.com"})
      :ok

      iex> SchemaContext.update_schema(:missing, %SchemaContext{url: "www.org.net"})
      :no_such_context

  """
  @spec update_context(atom, __MODULE__.t) :: :ok | :no_such_context
  def update_context(name, context) do
    GenServer.call(__MODULE__, {:add, %{name: name, context: context}})
  end

  @doc """
  Retrieves the context registered with the given name.  If there is no context registered this function returns `:no_such_context`

  ## Parameters

    - name: The registered name of the context to retrieve

  ## Examples

      iex> SchemaContext.get(:missing)
      :no_such_context

      iex> SchemaContext.add_schema(:auth, %SchemaContext{url: "com.com.com"})
      iex> SchemaContext.get(:auth)
      %SchemaContext{url: "com.com.com", headers: []}

  """
  @spec get(atom) :: __MODULE__.t | :no_such_context
  def get(name) do
    __MODULE__
    |> :ets.lookup(name)
    |> case do
         nil ->
           :no_such_context
         context ->
           context
       end
  end

  def handle_call({:add, %{name: name, context: context}}, _from, state) do
    __MODULE__
    |> :ets.lookup(name)
    |> case do
         nil ->
           :ets.insert(__MODULE__, {name, context})
           {:ok, :ok, state}
         _doc ->
           {:ok, :context_already_configured, state}
       end
  end

  def handle_call({:update, %{name: name, context: context}}, _from, state) do
    __MODULE__
    |> :ets.lookup(name)
    |> case do
         nil ->
           {:ok, :no_such_context, state}
         _old_doc ->
           :ets.insert(__MODULE__, {name, context})
           {:ok, :ok, state}
       end
  end
end