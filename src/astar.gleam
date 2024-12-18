import defaultdict.{type DefaultDict}
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import gleam/set.{type Set}
import gleamy/priority_queue as pq
import position.{type Position}

type MaybeDistance(d) {
  Infinity
  Finite(d)
}

pub type Distance(v, d) {
  Distance(
    zero: d,
    between: fn(v, v) -> d,
    add: fn(d, d) -> d,
    compare_real: fn(d, d) -> Order,
    estimate_to_goal: fn(v) -> d,
  )
}

pub fn int_distance(between: fn(v, v) -> Int, estimate_to_goal: fn(v) -> Int) {
  Distance(
    between:,
    estimate_to_goal:,
    zero: 0,
    add: int.add,
    compare_real: int.compare,
  )
}

pub fn float_distance(
  between: fn(v, v) -> Float,
  estimate_to_goal: fn(v) -> Float,
) {
  Distance(
    between:,
    estimate_to_goal:,
    zero: 0.0,
    add: float.add,
    compare_real: float.compare,
  )
}

pub fn manhattan_distance(goal: Position) {
  int_distance(position.distance, position.distance(_, goal))
}

type Node(v, d) {
  Node(value: v, dist_from_start: d, dist_to_end_estimate: d)
}

type DistanceMap(v, d) =
  defaultdict.DefaultDict(v, MaybeDistance(d))

fn new_distance_map() {
  defaultdict.new(Infinity)
}

fn record_distance(distance_map, v, s) {
  defaultdict.insert(distance_map, v, Finite(s))
}

fn get_distance(distance_map, v) {
  defaultdict.get(distance_map, v)
}

fn known_distances(distance_map: DistanceMap(v, d)) {
  defaultdict.to_dict(distance_map)
  |> dict.to_list
  |> list.filter_map(fn(kv) {
    let #(k, v) = kv
    case v {
      Infinity -> Error(Nil)
      Finite(known) -> Ok(#(k, known))
    }
  })
  |> dict.from_list
}

fn compare_unknown_distances(a, b, compare_finite) {
  case a, b {
    Infinity, Infinity -> order.Eq
    Infinity, Finite(_) -> order.Gt
    Finite(_), Infinity -> order.Lt
    Finite(s1), Finite(s2) -> compare_finite(s1, s2)
  }
}

fn compare_nodes(compare_distance: fn(d, d) -> Order) {
  fn(a: Node(v, d), b: Node(v, d)) {
    compare_distance(a.dist_to_end_estimate, b.dist_to_end_estimate)
  }
}

pub type SearchResult(v, d) {
  NotFound
  Found(
    found_goals: List(v),
    min_distance: d,
    came_from: DefaultDict(v, Set(v)),
    distances: Dict(v, d),
  )
}

pub fn all_states_on_paths(search_result: SearchResult(v, d)) -> Set(v) {
  case search_result {
    NotFound -> set.new()
    Found(goals, _, came_from, _) ->
      do_all_states_on_paths(set.from_list(goals), came_from, set.new())
  }
}

fn do_all_states_on_paths(
  level: Set(v),
  came_from: DefaultDict(v, Set(v)),
  acc: Set(v),
) {
  case set.is_empty(level) {
    True -> acc
    False -> {
      let acc = set.union(acc, level)
      let next_level =
        set.fold(level, set.new(), fn(next_level, v) {
          defaultdict.get(came_from, v) |> set.union(next_level)
        })
      do_all_states_on_paths(next_level, came_from, acc)
    }
  }
}

pub fn search_all_with_filter(
  starting_from starts: List(v),
  until is_goal: fn(v) -> Bool,
  try_neighbors get_neighbors: fn(v) -> List(v),
  such_that filter: fn(v, d) -> Bool,
  minimizing distance: Distance(v, d),
) {
  search(starts, is_goal, get_neighbors, filter, distance, None)
}

pub fn search_one_with_filter(
  starting_from starts: List(v),
  until is_goal: fn(v) -> Bool,
  try_neighbors get_neighbors: fn(v) -> List(v),
  such_that filter: fn(v, d) -> Bool,
  minimizing distance: Distance(v, d),
) {
  search(starts, is_goal, get_neighbors, filter, distance, Some(1))
}

pub fn search_all(
  starting_from starts: List(v),
  until is_goal: fn(v) -> Bool,
  try_neighbors get_neighbors: fn(v) -> List(v),
  minimizing distance: Distance(v, d),
) {
  search(starts, is_goal, get_neighbors, fn(_, _) { True }, distance, None)
}

pub fn search_one(
  starting_from starts: List(v),
  until is_goal: fn(v) -> Bool,
  try_neighbors get_neighbors: fn(v) -> List(v),
  minimizing distance: Distance(v, d),
) {
  search(starts, is_goal, get_neighbors, fn(_, _) { True }, distance, Some(1))
}

fn make_result(final_state: SearchState(v, d)) {
  case final_state.found_goals {
    [] -> NotFound
    [last, ..] as goals -> {
      let goal_values = goals |> list.map(fn(node) { node.value })
      Found(
        goal_values,
        last.dist_from_start,
        final_state.came_from,
        known_distances(final_state.dists_from_start),
      )
    }
  }
}

type SearchState(v, d) {
  SearchState(
    open_set: pq.Queue(Node(v, d)),
    dists_from_start: DistanceMap(v, d),
    came_from: defaultdict.DefaultDict(v, Set(v)),
    found_goals: List(Node(v, d)),
    goal_limit: Option(Int),
  )
}

fn search(
  starting_from starts: List(v),
  until is_goal: fn(v) -> Bool,
  try_neighbors get_neighbors: fn(v) -> List(v),
  such_that filter: fn(v, d) -> Bool,
  minimizing distance: Distance(v, d),
  up_to limit: Option(Int),
) {
  let start_nodes =
    list.map(starts, fn(start) {
      Node(start, distance.zero, distance.estimate_to_goal(start))
    })
  let open_set = pq.from_list(start_nodes, compare_nodes(distance.compare_real))
  let came_from = defaultdict.new(set.new())
  let dists_from_start =
    list.fold(starts, new_distance_map(), fn(map, start) {
      record_distance(map, start, distance.zero)
    })
  let found_goals = list.filter(start_nodes, fn(n) { is_goal(n.value) })

  try_search(
    SearchState(
      open_set:,
      dists_from_start:,
      came_from:,
      found_goals: found_goals,
      goal_limit: limit,
    ),
    is_goal,
    get_neighbors,
    filter,
    distance,
  )
}

fn try_search(
  state: SearchState(v, d),
  is_goal: fn(v) -> Bool,
  get_neighbor_values: fn(v) -> List(v),
  filter: fn(v, d) -> Bool,
  distance: Distance(v, d),
) {
  case try_next(state, distance) {
    Ok(#(curr, state)) -> {
      get_neighbors(state, get_neighbor_values, curr, distance)
      |> list.filter(fn(neighbor) {
        filter(neighbor.value, neighbor.dist_from_start)
      })
      |> list.fold(state, fn(state, neighbor) {
        let is_goal = is_goal(neighbor.value)
        update_search_state(state, curr.value, neighbor, is_goal)
      })
      |> try_search(is_goal, get_neighbor_values, filter, distance)
    }
    Error(Nil) -> make_result(state)
  }
}

fn try_next(search_state: SearchState(v, d), distance: Distance(v, d)) {
  use #(node, open_set) <- result.try(pq.pop(search_state.open_set))
  let current_best = case search_state.found_goals {
    [goal, ..] -> Finite(goal.dist_from_start)
    [] -> Infinity
  }
  let compared_to_bound =
    compare_unknown_distances(
      Finite(node.dist_from_start),
      current_best,
      distance.compare_real,
    )
  case compared_to_bound {
    order.Lt | order.Eq -> Ok(#(node, SearchState(..search_state, open_set:)))
    order.Gt -> Error(Nil)
  }
}

fn get_neighbors(
  state: SearchState(v, d),
  get_neighbor_values: fn(v) -> List(v),
  curr: Node(v, d),
  distance: Distance(v, d),
) {
  let Node(curr_value, curr_dist_from_start, _) = curr
  get_neighbor_values(curr_value)
  |> list.filter_map(fn(neighbor) {
    let dist_from_curr = distance.between(curr_value, neighbor)
    let dist_from_start = curr_dist_from_start |> distance.add(dist_from_curr)
    let compared_to_known_dist =
      compare_unknown_distances(
        Finite(dist_from_start),
        get_distance(state.dists_from_start, neighbor),
        distance.compare_real,
      )

    let goal_limit = case state.goal_limit {
      Some(remaining) -> remaining
      None -> 1
    }

    let can_lead_to_goal = case compared_to_known_dist {
      // should be unreachable for valid heuristics
      order.Lt -> True
      order.Eq -> goal_limit > 0
      order.Gt -> False
    }

    case can_lead_to_goal {
      True -> {
        let dist_to_end_estimate =
          dist_from_start |> distance.add(distance.estimate_to_goal(neighbor))
        Ok(Node(neighbor, dist_from_start, dist_to_end_estimate))
      }
      False -> Error(Nil)
    }
  })
}

fn update_search_state(
  state: SearchState(v, d),
  from_value: v,
  to_node: Node(v, d),
  is_goal: Bool,
) {
  let open_set = pq.push(state.open_set, to_node)
  let dists_from_start =
    record_distance(
      state.dists_from_start,
      to_node.value,
      to_node.dist_from_start,
    )
  let came_from =
    defaultdict.upsert(state.came_from, to_node.value, set.insert(_, from_value))
  let found_goals = case is_goal {
    True -> [to_node, ..state.found_goals]
    False -> state.found_goals
  }
  let goal_limit = case state.goal_limit {
    Some(remaining) -> Some(remaining - 1)
    None -> None
  }
  SearchState(
    open_set:,
    dists_from_start:,
    came_from:,
    found_goals:,
    goal_limit:,
  )
}
