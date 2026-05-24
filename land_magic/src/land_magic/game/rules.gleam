import gleam/list
import land_magic/model/types.{
  type Land,
  type Model,
  Model,
  type Prompt,
  type Winner,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  NoWinner,
  HasWinner,
  GameOver,
  NotPicked,
  Picked,
  type PickResult,
}

pub fn finalize_after_action(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> model
  }
}

pub fn log_and_prompt(model: Model, entry: String, prompt: Prompt) -> Model {
  let model = log_action(model, entry)
  Model(..model, prompt: prompt)
}

pub fn log_action(model: Model, entry: String) -> Model {
  Model(..model, log: [entry, ..model.log])
}

pub fn winner(model: Model) -> Winner {
  case has_all_five(model.player_one.battlefield) {
    True -> HasWinner(PlayerOne)
    False ->
      case has_all_five(model.player_two.battlefield) {
        True -> HasWinner(PlayerTwo)
        False -> NoWinner
      }
  }
}

pub fn has_all_five(cards: List(Land)) -> Bool {
  contains_land(cards, Plains)
    && contains_land(cards, Island)
    && contains_land(cards, Swamp)
    && contains_land(cards, Mountain)
    && contains_land(cards, Forest)
}

pub fn battlefield_exists(model: Model) -> Bool {
  list.length(model.player_one.battlefield) + list.length(model.player_two.battlefield) > 0
}

pub fn has_counter_cost(cards: List(Land)) -> Bool {
  contains_land(cards, Island) && count_non_island(cards) > 0
}

pub fn count_non_island(cards: List(Land)) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == Island {
        True -> count_non_island(rest)
        False -> 1 + count_non_island(rest)
      }
  }
}

pub fn contains_land(cards: List(Land), target: Land) -> Bool {
  case cards {
    [] -> False
    [card, ..rest] ->
      case card == target {
        True -> True
        False -> contains_land(rest, target)
      }
  }
}

pub fn remove_at(cards: List(Land), target_index: Int, current_index: Int) -> #(List(Land), PickResult(Land)) {
  case cards {
    [] -> #([], NotPicked)
    [card, ..rest] ->
      case current_index == target_index {
        True -> #(rest, Picked(card))
        False -> {
          let #(new_rest, pick) = remove_at(rest, target_index, current_index + 1)
          #([card, ..new_rest], pick)
        }
      }
  }
}
