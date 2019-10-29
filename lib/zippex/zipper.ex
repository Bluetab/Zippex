defmodule Zippex.Zipper do
  @moduledoc """
  A Zipper is a representation of an aggregate data structure which
  allows it to be traversed and updated arbitrarily. This module
  implements tree-like semantics for traversing a data structure.

  ## Focus

  The current node of the zipper, also known as the focus node, can be
  retrieved by calling the `focus/1` function. The following functions
  provide other information relating to the focus node:

  * `lefts` - returns the left siblings of the focus node
  * `rights` - returns the rights siblings of the focus node
  * `path` - returns the path to the focus node from the root

  ## Traversal

  The focus can be moved using the following functions:

  * `head`      - moves to the root node
  * `down`      - moves to the first child of the focus node
  * `up`        - moves to the parent of the focus node
  * `left`      - moves to the left sibling of the focus node
  * `leftmost`  - moves to the leftmost sibling of the focus node
  * `right`     - moves to the right sibling of the focus node
  * `rightmost` - moves to the rightmost sibling of the focus node
  * `next`      - moves to the next node in a depth-first traversal
  * `prev`      - moves to the previous node in a depth-first traversal

  ## Enumeration

  `Zipper` implements the `Enumerable` protocol, which allows it's values
  to be enumerated in a depth-first traversal.

  ## Updates

  The focus node can be modified using the functions `edit/2` or `edit/3`.
  It can be removed, along with it's children, using the `remove/1` function,
  after which the focus is moved to the previous node in a depth-first
  traversal.

  """

  import Kernel, except: [node: 1]

  alias Zippex.Context
  alias Zippex.Meta
  alias Zippex.Zipper

  defstruct [:spec, :node, :ctx]

  @type t :: %__MODULE__{spec: Meta.t(), node: element, ctx: Context.t() | :end}

  @type edit_fun :: (element -> element)
  @type edit_with_args_fun :: (element, args -> element)
  @type element :: any
  @type args :: any

  @doc """
  Returns a new Zipper for a given `node` element.

  `is_branch_fun` receives a node and returns `true` if it is a branch, or 
  `false` otherwise.

  `children_fun` receives a node (which is a branch) and returns a list of
  it's child nodes.

  `make_node_fun` receives a parent node and a list of child nodes and
  returns a new node.
  """
  @spec new(Meta.is_branch_fun(), Meta.children_fun(), Meta.make_node_fun(), element) :: t
  def new(is_branch, children, make_node, root) do
    spec = Meta.new(is_branch, children, make_node)

    %Zipper{
      node: root,
      spec: spec,
      ctx: %Context{}
    }
  end

  @doc """
  Returns the focus node of a zipper.
  """
  @spec focus(t) :: element
  def focus(zipper)
  def focus(%Zipper{node: n}), do: n

  @doc """
  Returns the root node of the zipper.
  """
  @spec root(t) :: element
  def root(%Zipper{} = zipper) do
    zipper |> head() |> focus()
  end

  @doc """
  Returns the path to the focus node.
  """
  @spec path(t) :: list(element)
  def path(%Zipper{ctx: ctx}) do
    Context.path(ctx, [])
  end

  @doc """
  Returns the left siblings of the focus node.
  """
  @spec lefts(t) :: list(element)
  def lefts(%Zipper{ctx: %{left: ls}}), do: ls

  @doc """
  Returns the right siblings of the focus node.
  """
  @spec rights(t) :: list(element)
  def rights(%Zipper{ctx: %{right: rs}}), do: rs

  @doc """
  Moves to the head of the zipper.
  """
  @spec head(t) :: element
  def head(%Zipper{} = zipper) do
    case up(zipper) do
      nil -> leftmost(zipper)
      z -> head(z)
    end
  end

  @doc """
  Moves to the left sibling of the focus node.

  Returns the updated zipper, or `nil` if the focus node has no left sibling.
  """
  @spec left(t) :: t | nil
  def left(%Zipper{node: n, ctx: ctx} = zipper) do
    case ctx do
      %{left: []} ->
        nil

      %{left: [prev | left], right: right} ->
        ctx = %{ctx | left: left, right: [n | right]}
        %{zipper | node: prev, ctx: ctx}
    end
  end

  @doc """
  Moves to the leftmost sibling of the focus node.

  Returns the updated zipper.
  """
  @spec leftmost(t) :: t
  def leftmost(%Zipper{node: n, ctx: ctx} = zipper) do
    case ctx do
      %{left: []} ->
        zipper

      %{left: ls, right: rs} ->
        [leftmost | right] = Enum.reduce(ls, [n | rs], &[&1 | &2])
        ctx = %{ctx | left: [], right: right}
        %{zipper | node: leftmost, ctx: ctx}
    end
  end

  @doc """
  Moves to the right sibling of the focus node.

  Returns the updated zipper, or `nil` if the focus node has no right sibling.
  """
  @spec right(t) :: t | nil
  def right(%Zipper{node: n, ctx: ctx} = zipper) do
    case ctx do
      %{right: []} ->
        nil

      %{left: left, right: [next | right]} ->
        ctx = %{ctx | left: [n | left], right: right}
        %{zipper | node: next, ctx: ctx}
    end
  end

  @doc """
  Moves to the rightmost sibling of the focus node.

  Returns the updated zipper.
  """
  @spec rightmost(t) :: t
  def rightmost(%Zipper{node: n, ctx: ctx} = zipper) do
    case ctx do
      %{right: []} ->
        zipper

      %{left: ls, right: rs} ->
        [rightmost | left] = Enum.reduce(rs, [n | ls], &[&1 | &2])
        ctx = %{ctx | left: left, right: []}
        %{zipper | node: rightmost, ctx: ctx}
    end
  end

  @doc """
  Moves to the parent of the focus node.

  Returns the updated zipper, or `nil` if the focus node has no parent.
  """
  @spec up(t) :: t | nil
  def up(%Zipper{node: n, ctx: ctx, spec: spec} = zipper) do
    case ctx do
      %{parent: nil} ->
        nil

      %{parent: parent, ctx: parent_ctx, dirty: false} ->
        %{zipper | node: parent, ctx: parent_ctx}

      %{left: left, right: right, parent: parent, ctx: parent_ctx, dirty: true} ->
        children = Enum.reverse(left) ++ [n | right]
        parent = Meta.make_node(spec, parent, children)
        %{zipper | node: parent, ctx: %{parent_ctx | dirty: true}}
    end
  end

  @doc """
  Moves to the first child of the focus node.

  Returns the updated zipper, or `nil` if the focus node has no children.
  """
  @spec down(t) :: t | nil
  def down(%Zipper{ctx: parent_ctx, node: parent, spec: spec} = zipper) do
    if Meta.is_branch(spec, parent) do
      case Meta.children(spec, parent) do
        [child | right] ->
          ctx = %Context{left: [], right: right, parent: parent, ctx: parent_ctx}
          %{zipper | node: child, ctx: ctx}

        _ ->
          nil
      end
    end
  end

  @doc """
  Moves to the next node of the focus node in a depth-first traversal.
  """
  @spec next(t) :: t
  def next(%Zipper{spec: spec, node: n} = zipper) do
    if Meta.is_branch(spec, n) do
      down(zipper)
    else
      case right(zipper) do
        nil -> next_recur(zipper)
        right -> right
      end
    end
  end

  @spec next_recur(t) :: t
  defp next_recur(%Zipper{} = zipper) do
    case up(zipper) do
      nil ->
        %{zipper | ctx: :end}

      z ->
        case right(z) do
          nil -> next_recur(z)
          right -> right
        end
    end
  end

  @doc """
  Moves to the previous node of the focus node in a depth-first traversal.
  """
  @spec prev(t) :: t
  def prev(%Zipper{ctx: ctx} = zipper) do
    case ctx do
      %{left: []} -> up(zipper)
      _ -> prev_recur(zipper)
    end
  end

  @spec prev_recur(t) :: t
  defp prev_recur(%Zipper{} = zipper) do
    case down(zipper) do
      nil ->
        zipper

      z ->
        z |> rightmost() |> prev_recur()
    end
  end

  @doc """
  Removes the focus node, moving the focus to the node that would have
  preceded it in a depth-first traversal.
  """
  @spec remove(t) :: t
  def remove(%Zipper{ctx: ctx, spec: spec} = zipper) do
    case ctx do
      %{ctx: nil} ->
        raise(ArgumentError, "can't remove root")

      %{left: [], right: right, parent: parent, ctx: parent_ctx} ->
        parent_ctx = %{parent_ctx | dirty: true}
        %{zipper | node: Meta.make_node(spec, parent, right), ctx: parent_ctx}

      %{left: [l | ls]} ->
        ctx = %{ctx | left: ls, dirty: true}
        %{zipper | node: l, ctx: ctx} |> remove_prev()
    end
  end

  @spec remove_prev(t) :: t
  defp remove_prev(%Zipper{} = zipper) do
    case down(zipper) do
      nil -> zipper
      z -> z |> rightmost() |> remove_prev()
    end
  end

  @doc """
  Modifies the focus node by applying a function to it.
  """
  @spec edit(t, edit_fun) :: t
  def edit(%Zipper{node: n, ctx: ctx} = zipper, fun) do
    %{zipper | node: fun.(n), ctx: %{ctx | dirty: true}}
  end

  @doc """
  Modifies the focus node by applying a function to it.
  """
  @spec edit(t, edit_with_args_fun, args) :: t
  def edit(%Zipper{node: n, ctx: ctx} = zipper, fun, args) do
    %{zipper | node: fun.(n, args), ctx: %{ctx | dirty: true}}
  end

  defimpl Enumerable do
    @impl true
    def reduce(zipper, acc, fun)
    def reduce(_zipper, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(zipper, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(zipper, &1, fun)}

    def reduce(%Zipper{ctx: ctx, node: n} = zipper, {:cont, acc}, fun) do
      case ctx do
        :end ->
          {:done, acc}

        _ ->
          zipper
          |> Zipper.next()
          |> reduce(fun.(n, acc), fun)
      end
    end

    @impl true
    def count(_zipper), do: {:error, __MODULE__}

    @impl true
    def member?(_zipper, _element), do: {:error, __MODULE__}

    @impl true
    def slice(_zipper), do: {:error, __MODULE__}
  end
end
