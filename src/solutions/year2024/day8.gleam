import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/set
import grid
import input
import parse
import position

fn antinode_pair(grid, pair) {
  let #(a, b) = pair
  let delta = position.sub(a, b)
  set.new()
  |> set.insert(position.add(a, delta))
  |> set.insert(position.sub(b, delta))
  |> set.filter(grid.has_position(grid, _))
}

fn scan_in_direction(grid, position, delta) {
  use <- bool.guard(!grid.has_position(grid, position), set.new())
  let next = position.add(position, delta)
  scan_in_direction(grid, next, delta) |> set.insert(position)
}

fn antinode_line(grid, pair) {
  let #(a, b) = pair
  let step = position.sub(a, b) |> position.reduce()
  let forward = scan_in_direction(grid, a, step)
  let backward = scan_in_direction(grid, a, position.negate(step))
  set.union(forward, backward)
}

pub fn main() {
  let grid =
    input.get()
    |> parse.grid("\n", "")

  let cells =
    grid
    |> grid.to_list
    |> list.filter(fn(cell) { cell.value != "." })

  let groups = cells |> list.group(fn(cell) { cell.value }) |> dict.values

  let node_pairs =
    list.flat_map(groups, fn(group) {
      group
      |> list.map(fn(cell) { cell.position })
      |> list.combination_pairs
    })

  node_pairs
  |> list.map(antinode_pair(grid, _))
  |> list.fold(set.new(), set.union)
  |> set.size
  |> io.debug

  node_pairs
  |> list.map(antinode_line(grid, _))
  |> list.fold(set.new(), set.union)
  |> set.size
  |> io.debug
}
