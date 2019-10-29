defmodule Zippex.Meta do
  @moduledoc """
  The metadata of a `Zippex` zipper. The `Meta` struct contains the following fields:

  * `is_branch` - A function that receives a node and returns `true` if the node is a branch
  * `children`  - A function that receives a node and returns it's children
  * `make_node` - A function that receives a node and a list of children and returns a new node

  """
  alias Zippex
  alias Zippex.Meta

  defstruct [:is_branch, :children, :make_node]
  @type element :: Zippex.element()
  @type is_branch_fun :: (element -> boolean)
  @type children_fun :: (element -> list(element))
  @type make_node_fun :: (element, list(element) -> element)

  @type t :: %__MODULE__{
          is_branch: is_branch_fun,
          children: children_fun,
          make_node: make_node_fun
        }

  @doc "Returns a new `Meta` struct"
  @spec new(is_branch_fun, children_fun, make_node_fun) :: t
  def new(is_branch, children, make_node) do
    %__MODULE__{is_branch: is_branch, children: children, make_node: make_node}
  end

  @doc "Applies the `make_node` function on a node and list of children"
  @spec make_node(t, element, list(element)) :: element
  def make_node(%Meta{make_node: fun}, parent, children) do
    fun.(parent, children)
  end

  @doc "Applies the `children` function on a node"
  @spec children(t, element) :: list(element)
  def children(%Meta{children: fun}, element) do
    fun.(element)
  end

  @doc "Applies the `is_branch` function on a node"
  @spec is_branch(t, element) :: boolean
  def is_branch(%Meta{is_branch: fun}, element) do
    fun.(element)
  end
end
