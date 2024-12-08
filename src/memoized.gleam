import gleam/dict
import gleam/list
import gleam/pair
import gleam/yielder.{type Yielder}

pub type Memoized(a, b) {
  Memoized(call: fn(a) -> #(b, Memoized(a, b)))
}

fn call(a, cache: dict.Dict(a, b), f: fn(a) -> b) -> #(b, Memoized(a, b)) {
  let b = case dict.get(cache, a) {
    Error(Nil) -> f(a)
    Ok(b) -> b
  }
  let cache = dict.insert(cache, a, b)
  #(b, Memoized(call: call(_, cache, f)))
}

pub fn one(f: fn(a) -> b) -> Memoized(a, b) {
  Memoized(call: call(_, dict.new(), f))
}

pub fn two(f: fn(a, b) -> c) -> Memoized(#(a, b), c) {
  one(fn(ab: #(a, b)) { f(ab.0, ab.1) })
}

pub fn three(f: fn(a, b, c) -> d) -> Memoized(#(a, b, c), d) {
  one(fn(abc: #(a, b, c)) { f(abc.0, abc.1, abc.2) })
}

pub fn map(xs: List(a), m: Memoized(a, b)) -> #(List(b), Memoized(a, b)) {
  {
    use #(ys, m), x <- list.fold(xs, #([], m))
    let #(y, m) = m.call(x)
    #([y, ..ys], m)
  }
  |> pair.map_first(list.reverse)
}

pub fn yield_map(xs: Yielder(a), f: fn(a) -> b) -> Yielder(#(b, Memoized(a, b))) {
  let m = one(f)
  use #(m, xs) <- yielder.unfold(#(m, xs))
  case yielder.step(xs) {
    yielder.Done -> yielder.Done
    yielder.Next(a, rest) -> {
      let #(b, m) = m.call(a)
      yielder.Next(#(b, m), #(m, rest))
    }
  }
}
