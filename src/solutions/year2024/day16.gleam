import defaultdict
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import gleamy/priority_queue
import grid.{type Grid}
import input
import parse
import position

type Node {
  Node(cell: grid.Cell(String), heading: position.Direction)
}

const wall = "#"

const end = "E"

const start = "S"

fn neighbors(node: Node, grid: Grid(String)) {
  let left = position.rotate_left(node.heading)
  let right = position.rotate_right(node.heading)
  let neighbor_dirs = [left, node.heading, right]
  neighbor_dirs
  |> list.filter_map(fn(dir) {
    use neighbor <- result.try(grid.neighbor(grid, node.cell, dir))
    use <- bool.guard(neighbor.value == wall, Error(Nil))
    Ok(Node(neighbor, dir))
  })
}

type Distance {
  Infinity
  Known(Int)
}

fn compare_distance(a: Distance, b: Distance) {
  case a, b {
    Infinity, Infinity -> order.Eq
    _, Infinity -> order.Lt
    Infinity, _ -> order.Gt
    Known(a), Known(b) -> int.compare(a, b)
  }
}

fn min_distance(a: Distance, b: Distance) {
  case compare_distance(a, b) {
    order.Lt | order.Eq -> a
    order.Gt -> b
  }
}

fn weight(from: Node, to: Node) {
  let distance = position.distance(from.cell.position, to.cell.position)
  case from.heading != to.heading {
    True -> 1000 + distance
    False -> distance
  }
}

type Edge {
  Edge(node: Node, weight: Int)
}

fn compare_edges(a: Edge, b: Edge) {
  int.compare(a.weight, b.weight)
}

fn search(start: Node, grid: Grid(String)) {
  let first_edge = Edge(node: start, weight: 0)
  do_search(
    priority_queue.new(compare_edges) |> priority_queue.push(first_edge),
    defaultdict.new(Infinity) |> defaultdict.insert(start, Known(0)),
    defaultdict.new(set.new()),
    grid,
  )
}

fn do_search(pq, distances, parents, grid) {
  case priority_queue.pop(pq) {
    Error(Nil) -> #(distances, parents)
    Ok(#(Edge(node, _), pq)) if node.cell.value == end ->
      do_search(pq, distances, parents, grid)
    Ok(#(Edge(node, path_weight), pq)) -> {
      let frontier =
        neighbors(node, grid)
        |> list.filter_map(fn(neighbor_node) {
          let new_path_weight = path_weight + weight(node, neighbor_node)
          let known_path_weight = defaultdict.get(distances, neighbor_node)
          case compare_distance(Known(new_path_weight), known_path_weight) {
            order.Lt | order.Eq ->
              Ok(Edge(node: neighbor_node, weight: new_path_weight))
            order.Gt -> Error(Nil)
          }
        })
      let #(pq, distances, parents) =
        list.fold(frontier, #(pq, distances, parents), fn(acc, neighbor) {
          let #(pq, distances, parents) = acc
          let pq = priority_queue.push(pq, neighbor)
          let distances =
            defaultdict.insert(distances, neighbor.node, Known(neighbor.weight))
          let parents =
            defaultdict.upsert(parents, neighbor.node, set.insert(_, node))
          #(pq, distances, parents)
        })

      do_search(pq, distances, parents, grid)
    }
  }
}

fn tiles_on_shortest_paths(
  parents: defaultdict.DefaultDict(Node, set.Set(Node)),
  curr: Node,
  visited: set.Set(Node),
) {
  let visited = set.insert(visited, curr)
  let curr_parents =
    defaultdict.get(parents, curr)
    |> set.filter(fn(parent) { !set.contains(visited, parent) })
  set.fold(curr_parents, visited, fn(visited, parent) {
    tiles_on_shortest_paths(parents, parent, visited)
  })
}

pub fn main() {
  let grid = input.get() |> parse.grid("\n", "")
  let assert Ok(start) = grid.find(grid, fn(cell) { cell.value == start })
  let assert Ok(end) = grid.find(grid, fn(cell) { cell.value == end })
  let start = Node(cell: start, heading: position.Right)
  let #(distances, parents) = search(start, grid)

  let end_nodes =
    defaultdict.filter(distances, fn(node, _) { node.cell == end })
  let min_distance = end_nodes |> defaultdict.reduce(min_distance)

  let assert Known(known_min_distance) = min_distance
  known_min_distance |> io.debug

  let min_end_nodes =
    end_nodes
    |> defaultdict.keys
    |> list.filter(fn(node) { defaultdict.get(distances, node) == min_distance })

  list.fold(min_end_nodes, set.new(), fn(visited, node) {
    tiles_on_shortest_paths(parents, node, visited)
  })
  |> set.map(fn(node) { node.cell.position })
  |> set.size
  |> io.debug
}
