defmodule Zippex.Context do
  @moduledoc """
  The context of a `Zippex` zipper. This module is used internally by Zippex and should
  not be accessed directly. The `Context` struct contains the following fields:

  * `parent` - The parent of the focus node (or nil)
  * `ctx`    - The parent context (or nil)
  * `left`   - A list of left siblings of the focus node
  * `right`  - A list of right siblings of the focus node
  * `dirty`  - `true` iff the focus node or any of it's children have been modified

  """
  alias Zippex.Context

  defstruct [:parent, :ctx, left: [], right: [], dirty: false]

  @type element :: Zippex.element()
  @type t :: %__MODULE__{
          left: list(element),
          right: list(element),
          parent: element | nil,
          ctx: t | nil,
          dirty: boolean
        }

  @doc """
  Returns the path to the focus node.
  """
  @spec path(t, list(element)) :: list(element)
  def path(context, path)

  def path(%Context{parent: nil}, path), do: path

  def path(%Context{parent: parent, ctx: parent_ctx}, path) do
    path(parent_ctx, [parent | path])
  end
end
