import gleam/dict
import gleam/list
import gleam/option
import gleam/result

pub type DefaultDict(k, v) {
  DefaultDict(default: v, dict: dict.Dict(k, v))
}

pub fn new(default: v) -> DefaultDict(k, v) {
  DefaultDict(default:, dict: dict.new())
}

pub fn from_list(xs: List(#(k, v)), default: v) -> DefaultDict(k, v) {
  DefaultDict(default:, dict: dict.from_list(xs))
}

pub fn new_counter() -> DefaultDict(k, Int) {
  new(0)
}

pub fn counter_from_list(xs: List(k)) -> DefaultDict(k, Int) {
  list.map(xs, fn(x) { #(x, 1) }) |> from_list(0)
}

pub fn get(dd: DefaultDict(k, v), key: k) -> v {
  result.unwrap(dict.get(dd.dict, key), dd.default)
}

pub fn insert(dd: DefaultDict(k, v), key: k, value: v) -> DefaultDict(k, v) {
  DefaultDict(default: dd.default, dict: dict.insert(dd.dict, key, value))
}

pub fn upsert(
  dd: DefaultDict(k, v),
  key: k,
  fun: fn(v) -> v,
) -> DefaultDict(k, v) {
  let fun = fn(opt) { option.unwrap(opt, dd.default) |> fun }
  DefaultDict(..dd, dict: dict.upsert(dd.dict, key, fun))
}
