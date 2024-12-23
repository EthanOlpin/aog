import defaultdict
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import input
import parse

fn maxmimal_cliques(graph) {
  let r = set.new()
  let x = set.new()
  let p = defaultdict.keys(graph) |> set.from_list
  let get_edges = defaultdict.get(graph, _)
  do_maximal_cliques(r, p, x, get_edges, [])
}

fn do_maximal_cliques(r, p, x, get_edges, acc) {
  case set.is_empty(p) && set.is_empty(x) {
    True -> [r, ..acc]
    False ->
      set.to_list(p)
      |> do_maximal_cliques_of_neighbors(r, p, x, get_edges, acc)
  }
}

fn do_maximal_cliques_of_neighbors(neighbors, r, p, x, get_edges, acc) {
  case neighbors {
    [] -> acc
    [v, ..rest] -> {
      let nr = set.insert(r, v)
      let edges_n = get_edges(v)
      let np = set.intersection(p, edges_n)
      let nx = set.intersection(x, edges_n)
      let acc = do_maximal_cliques(nr, np, nx, get_edges, acc)
      let p = set.delete(p, v)
      let x = set.insert(x, v)
      do_maximal_cliques_of_neighbors(rest, r, p, x, get_edges, acc)
    }
  }
}

fn triangles(adjacent_pairs, graph) {
  let get_edges = defaultdict.get(graph, _)
  list.fold(adjacent_pairs, [], fn(triangles, pair) {
    let #(u, v) = pair
    let u_edges = get_edges(u)
    let v_edges = get_edges(v)
    let common = set.intersection(u_edges, v_edges)
    set.fold(common, triangles, fn(triangles, w) {
      let triangle = [u, v, w]
      [triangle, ..triangles]
    })
  })
}

pub fn main() {
  let adj_list =
    input.get()
    |> parse.lines
    |> list.filter_map(string.split_once(_, "-"))

  let graph =
    list.fold(adj_list, defaultdict.new(set.new()), fn(graph, pair) {
      let #(a, b) = pair
      defaultdict.upsert(graph, a, set.insert(_, b))
      |> defaultdict.upsert(b, set.insert(_, a))
    })

  triangles(adj_list, graph)
  |> list.filter(list.any(_, string.starts_with(_, "t")))
  |> list.map(list.sort(_, string.compare))
  |> list.unique
  |> list.length
  |> io.debug

  let assert Ok(largest_clique) =
    maxmimal_cliques(graph)
    |> list.reduce(fn(c1, c2) {
      case set.size(c1) > set.size(c2) {
        True -> c1
        False -> c2
      }
    })

  largest_clique
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
  |> io.println
}
