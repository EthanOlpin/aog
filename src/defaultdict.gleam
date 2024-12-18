import gleam/dict
import gleam/list
import gleam/option
import gleam/result

pub type DefaultDict(k, v) {
  DefaultDict(default: v, dict: dict.Dict(k, v))
}

pub type Counter(k) =
  DefaultDict(k, Int)

pub fn new(default: v) -> DefaultDict(k, v) {
  DefaultDict(default:, dict: dict.new())
}

pub fn from_list(xs: List(#(k, v)), default: v) -> DefaultDict(k, v) {
  DefaultDict(default:, dict: dict.from_list(xs))
}

pub fn new_counter() -> Counter(k) {
  new(0)
}

pub fn counter_from_list(xs: List(k)) -> Counter(k) {
  list.fold(xs, new_counter(), fn(dd, x) {
    upsert(dd, x, fn(count) { count + 1 })
  })
}

pub fn counter_add(
  dd: DefaultDict(k, Int),
  key: k,
  value: Int,
) -> DefaultDict(k, Int) {
  upsert(dd, key, fn(count) { count + value })
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

pub fn to_dict(dd: DefaultDict(k, v)) -> dict.Dict(k, v) {
  dd.dict
}

pub fn values(dd: DefaultDict(k, v)) -> List(v) {
  dict.values(dd.dict)
}

pub fn keys(dd: DefaultDict(k, v)) -> List(k) {
  dict.keys(dd.dict)
}
