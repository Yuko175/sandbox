import gleam/int
import gleam/list
import land_magic/game/rules
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Land,
  type Turn,
  type Player,
  type Model,
  type PickResult,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  Player,
  Picked,
  NotPicked,
}
import land_magic/state/players.{current_player, set_current_player}

pub fn draw_random_card(player: Player) -> #(Player, PickResult(Land)) {
  case player.deck {
    [] -> #(player, NotPicked)

    deck -> {
      let index = int.random(list.length(deck))
      case rules.remove_at(deck, index, 0) {
        #(new_deck, Picked(card)) -> #(Player(..player, deck: new_deck), Picked(card))
        _ -> #(player, NotPicked)
      }
    }
  }
}

pub fn draw_opening_hand(player: Player, count: Int) -> Player {
  case count {
    0 -> player
    _ ->
      case player.deck {
        [] -> player
        [card, ..rest] -> {
          let player = Player(..player, deck: rest, hand: [card, ..player.hand])
          draw_opening_hand(player, count - 1)
        }
      }
  }
}

pub fn new_player(turn: Turn) -> Player {
  case turn {
    PlayerOne ->
      Player(
        name: "プレイヤー1",
        deck: repeated_deck([Plains, Island, Swamp, Mountain, Forest], 5, []),
        hand: [],
        battlefield: [],
        graveyard: [],
      )

    PlayerTwo ->
      Player(
        name: "プレイヤー2",
        deck: repeated_deck([Forest, Mountain, Swamp, Island, Plains], 5, []),
        hand: [],
        battlefield: [],
        graveyard: [],
      )
  }
}

pub fn draw_turn_card(model: Model) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      rules.log_action(
        model,
        turn_name(model.turn) <> "は山札が空のため、ターン開始時に引けませんでした。",
      )

    [drawn_card, ..rest] -> {
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      rules.log_action(
        model,
        turn_name(model.turn) <> "がターン開始時に" <> land_name(drawn_card) <> "を引きました。",
      )
    }
  }
}

fn repeated_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  // Build the full deck by repeating `cycle` `times` times, then shuffle it.
  let deck = build_deck(cycle, times, acc)
  shuffle(deck, [])
}

fn build_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  case times {
    0 -> acc
    _ -> build_deck(cycle, times - 1, append_list(cycle, acc))
  }
}

fn append_list(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    [card, ..rest] -> [card, ..append_list(rest, acc)]
  }
}

fn shuffle(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    _ -> {
      let len = list.length(items)
      let index = int.random(len)
      case rules.remove_at(items, index, 0) {
        #(rest, Picked(card)) -> shuffle(rest, [card, ..acc])
        _ -> shuffle(items, acc)
      }
    }
  }
}
