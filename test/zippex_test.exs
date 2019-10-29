defmodule Tree do
  @moduledoc """
  A list-based Rose Tree implementation.
  The head of the list is the value of the node, the tail is the list of child nodes.
  """
  alias Zippex

  def t(value), do: [value]
  def t(value, children), do: [value | children]
  def set_value([_ | children], value), do: [value | children]
  def make_node([value | _], children), do: [value | children]
  def children(tree), do: tl(tree)
  def is_branch?([_, _ | _]), do: true
  def is_branch?(_), do: false
  def value([value | _]), do: value
  def value(%Zippex{} = z), do: z |> Zippex.focus() |> value()
  def zipper(tree), do: Zippex.new(&is_branch?/1, &children/1, &make_node/2, tree)
end

defmodule ZippexTest do
  use ExUnit.Case

  import Kernel, except: [node: 1]
  import Tree, only: [value: 1, set_value: 2, t: 1, t: 2]
  import Zippex

  defp t1, do: t(1337, [t(:foo), t(:bar)])
  defp t2, do: t(2112, [t4(), t(:quuz)])
  defp t3, do: t(:corge)
  defp t4, do: t(90_125, [t(:baz), t(:qux), t(:quux)])
  defp t5, do: t(1337, [t(:foo), t(:xyzzy)])
  defp t6, do: t(7331, [t(:foo), t(:bar)])

  setup _ do
    tree = t(42, [t1(), t2(), t3()])
    z = Tree.zipper(tree)
    %{tree: tree, z: z}
  end

  test "data is retained", %{tree: tree, z: z} do
    assert z |> root() == tree
  end

  test "down/1 moves to first child, returns nil if node has no children", %{z: z} do
    assert z |> down() |> value() == 1337
    assert z |> down() |> down() |> value() == :foo
    assert z |> down() |> down() |> down() == nil
  end

  test "up/1 moves to parent, returns nil if node has no parent", %{z: z} do
    assert z |> down() |> up() |> value() == 42
    assert z |> down() |> down() |> up() |> up() |> value() == 42
    assert z |> up() == nil
  end

  test "right/1 moves to right sibling, returns nil if node has no right sibling", %{z: z} do
    assert z |> down() |> right() |> value() == 2112
    assert z |> down() |> right() |> right() |> value() == :corge
    assert z |> down() |> right() |> right() |> right() == nil
  end

  test "left/1 moves to left sibling, returns nil if node has no right sibling", %{z: z} do
    assert z |> down() |> left() == nil
    assert z |> down() |> right() |> left() |> value() == 1337
    assert z |> down() |> down() |> right() |> left() |> value() == :foo
  end

  test "rightmost/1 moves to rightmost sibling", %{z: z} do
    assert z |> down() |> rightmost() |> value() == :corge
    assert z |> down() |> down() |> rightmost() |> value() == :bar
  end

  test "leftmost/1 moves to leftmost sibling", %{z: z} do
    assert z |> leftmost() |> value() == 42
    assert z |> down() |> right() |> leftmost() |> value() == 1337
    assert z |> down() |> down() |> right() |> leftmost() |> value() == :foo
  end

  test "root/1 from deep focus returns root node", %{z: z, tree: tree} do
    assert z |> down() |> right() |> root() == tree
  end

  test "edit/3 edits the node", %{z: z} do
    assert z |> down() |> down() |> right() |> edit(&set_value/2, :xyzzy) |> root() ==
             t(42, [t5(), t2(), t3()])

    assert z |> down() |> down() |> up() |> edit(&set_value/2, 7331) |> root() ==
             t(42, [t6(), t2(), t3()])
  end

  test "Enum.map traverses nodes in depth-first preorder", %{z: z} do
    assert z |> Enum.map(&value/1) ==
             [42, 1337, :foo, :bar, 2112, 90_125, :baz, :qux, :quux, :quuz, :corge]
  end

  test "Enum.find returns node with children", %{z: z} do
    v1 = t1() |> value()
    v4 = t4() |> value()
    assert z |> Enum.find(&(value(&1) == v1)) == t1()
    assert z |> Enum.find(&(value(&1) == v4)) == t4()
    assert z |> Enum.find(&(value(&1) == :missing)) == nil
  end

  test "Enum.reverse returns nodes in reverse of depth-first preorder traversal", %{z: z} do
    assert z |> Enum.reverse() |> Enum.map(&value/1) ==
             [:corge, :quuz, :quux, :qux, :baz, 90_125, 2112, :bar, :foo, 1337, 42]
  end

  test "Enum.member? returns true for member nodes", %{z: z} do
    assert Enum.member?(z, t4())
    assert Enum.member?(z, t1())
    refute Enum.member?(z, t6())
  end

  test "Enum.count returns count of nodes", %{z: z} do
    assert z |> Enum.count() == 11
  end

  test "remove/1 on leftmost node", %{z: z} do
    z = z |> down() |> remove()

    assert value(z) == 42
    assert root(z) == t(42, [t2(), t3()])
  end

  test "remove/1 on middle node", %{z: z} do
    z = z |> down() |> right() |> remove()

    assert value(z) == :bar
    assert root(z) == t(42, [t1(), t3()])
  end

  test "remove/1 on rightmost node", %{z: z} do
    z = z |> down() |> rightmost() |> remove()

    assert value(z) == :quuz
    assert root(z) == t(42, [t1(), t2()])
  end

  test "path", %{z: z} do
    assert z |> down() |> right() |> down() |> down() |> path() |> Enum.map(&value/1) ==
             [42, 2112, 90_125]
  end

  test "lefts", %{z: z} do
    assert z |> down() |> rightmost() |> lefts() |> Enum.map(&value/1) == [2112, 1337]
  end

  test "rights", %{z: z} do
    assert z |> down() |> rights() |> Enum.map(&value/1) == [2112, :corge]
  end
end
