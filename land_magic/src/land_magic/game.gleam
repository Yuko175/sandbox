import gleam/list
import land_magic/domain.{land_name, other_turn, turn_name}
import land_magic/state.{current_player, opponent_player, player_by_turn, set_current_player, set_opponent_player, set_player}
import land_magic/types.{
  type Land,
  type Turn,
  type Player,
  type Prompt,
  type Model,
  type PickResult,
  type Winner,
  type Msg,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  Player,
  Model,
  ChoosePlay,
  CounterWindow,
  ChoosePlainsTarget,
  ChooseSwampTarget,
  ChooseMountainTarget,
  ChooseForestDraw,
  EndTurnReady,
  GameOver,
  ResetGame,
  PlayCard,
  CounterWithIsland,
  PassCounter,
  ReturnFromGraveyard,
  DiscardOpponentCard,
  DestroyFromBattlefield,
  DrawForForest,
  FinishTurn,
  Picked,
  NotPicked,
  NoWinner,
  HasWinner,
}

pub fn init(_args: Nil) -> Model {
  let player_one = draw_opening_hand(new_player(PlayerOne), 4)
  let player_two = draw_opening_hand(new_player(PlayerTwo), 4)

  let model = Model(
    player_one: player_one,
    player_two: player_two,
    turn: PlayerOne,
    prompt: ChoosePlay,
    log: [
      "新しいゲームを開始しました。",
      "手札は公開され、すべての選択は手動です。",
    ],
    turn_number: 1,
  )

  begin_turn(model)
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ResetGame -> init(Nil)

    PlayCard(index) ->
      case model.prompt {
        ChoosePlay -> play_card(model, index)
        _ -> model
      }

    CounterWithIsland(index) ->
      case model.prompt {
        CounterWindow(card) -> counter_with_island(model, card, index)
        _ -> model
      }

    PassCounter ->
      case model.prompt {
        CounterWindow(card) -> resolve_play(model, card)
        _ -> model
      }

    ReturnFromGraveyard(index) ->
      case model.prompt {
        ChoosePlainsTarget(card) -> resolve_plains(model, card, index)
        _ -> model
      }

    DiscardOpponentCard(index) ->
      case model.prompt {
        ChooseSwampTarget(card) -> resolve_swamp(model, card, index)
        _ -> model
      }

    DestroyFromBattlefield(owner, index) ->
      case model.prompt {
        ChooseMountainTarget(card) -> resolve_mountain(model, card, owner, index)
        _ -> model
      }

    DrawForForest ->
      case model.prompt {
        ChooseForestDraw(card) -> resolve_forest(model, card)
        _ -> model
      }

    FinishTurn ->
      case model.prompt {
        ChoosePlay -> end_turn(model)
        ChooseMountainTarget(_) -> end_turn(model)
        EndTurnReady -> end_turn(model)
        _ -> model
      }
  }
}

fn play_card(model: Model, index: Int) -> Model {
  let current = current_player(model)

  case remove_at(current.hand, index, 0) {
    #(new_hand, Picked(card)) -> {
      let current = Player(..current, hand: new_hand)
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "をプレイしました。",
      )

      case has_counter_cost(opponent_player(model).hand) {
        True -> Model(..model, prompt: CounterWindow(card))
        False -> resolve_play(model, card)
      }
    }

    _ -> model
  }
}

fn counter_with_island(model: Model, card: Land, index: Int) -> Model {
  let defender = opponent_player(model)

  case remove_at(defender.hand, index, 0) {
    #(hand_without_discard, Picked(discarded_card)) ->
      case remove_first(hand_without_discard, Island) {
        #(final_hand, Picked(island_card)) -> {
          let defender = Player(
            ..defender,
            hand: final_hand,
            graveyard: [discarded_card, island_card, ..defender.graveyard],
          )
          let model = set_opponent_player(model, defender)
          let model = log_action(
            model,
            turn_name(other_turn(model.turn))
              <> "が島と"
              <> land_name(discarded_card)
              <> "を捨て、"
              <> land_name(card)
              <> "を打ち消しました。",
          )

          end_turn(model)
        }

        _ -> model
      }

    _ -> model
  }
}

fn resolve_play(model: Model, card: Land) -> Model {
  let current = current_player(model)
  let current = Player(..current, battlefield: [card, ..current.battlefield])
  let model = set_current_player(model, current)

  case card {
    Plains ->
      case current.graveyard {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が平地を解決しましたが、墓地に対象がありません。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が平地を解決しました。",
            ChoosePlainsTarget(card),
          )
      }

    Island ->
      finalize_after_action(
        log_and_prompt(model, turn_name(model.turn) <> "が島を解決しました。", EndTurnReady),
      )

    Swamp ->
      case opponent_player(model).hand {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が沼を解決しましたが、相手の手札がありません。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が沼を解決しました。",
            ChooseSwampTarget(card),
          )
      }

    Mountain ->
      case battlefield_exists(model) {
        True ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が山を解決しました。",
            ChooseMountainTarget(card),
          )
        False ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が山を解決しましたが、戦場に対象がありません。",
              EndTurnReady,
            ),
          )
      }

    Forest ->
      case current.deck {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が森を解決しましたが、山札が空です。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が森を解決しました。",
            ChooseForestDraw(card),
          )
      }
  }
}

fn resolve_plains(model: Model, _card: Land, index: Int) -> Model {
  let current = current_player(model)

  case remove_at(current.graveyard, index, 0) {
    #(new_graveyard, Picked(returned_card)) -> {
      let current = Player(..current, graveyard: new_graveyard, hand: [returned_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が平地で" <> land_name(returned_card) <> "を回収しました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_swamp(model: Model, _card: Land, index: Int) -> Model {
  let opponent = opponent_player(model)

  case remove_at(opponent.hand, index, 0) {
    #(new_hand, Picked(discarded_card)) -> {
      let opponent = Player(..opponent, hand: new_hand, graveyard: [discarded_card, ..opponent.graveyard])
      let model = set_opponent_player(model, opponent)
      let model = log_action(
        model,
        turn_name(other_turn(model.turn)) <> "が沼で" <> land_name(discarded_card) <> "を捨てました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_mountain(model: Model, _card: Land, owner: Turn, index: Int) -> Model {
  let target_player = player_by_turn(model, owner)

  case remove_at(target_player.battlefield, index, 0) {
    #(new_battlefield, Picked(destroyed_card)) -> {
      let target_player = Player(
        ..target_player,
        battlefield: new_battlefield,
        graveyard: [destroyed_card, ..target_player.graveyard],
      )
      let model = set_player(model, owner, target_player)
      let model = log_action(
        model,
        turn_name(model.turn)
          <> "が山で"
          <> turn_name(owner)
          <> "の"
          <> land_name(destroyed_card)
          <> "を破壊しました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_forest(model: Model, _card: Land) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      finalize_after_action(
        log_and_prompt(model, turn_name(model.turn) <> "は山札が空で引けませんでした。", EndTurnReady),
      )

    [drawn_card, ..rest] -> {
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が森で" <> land_name(drawn_card) <> "を引きました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }
  }
}

fn end_turn(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> {
      let next_turn = other_turn(model.turn)
      let model = Model(
        ..model,
        turn: next_turn,
        prompt: ChoosePlay,
        turn_number: model.turn_number + 1,
      )

      begin_turn(model)
    }
  }
}

fn begin_turn(model: Model) -> Model {
  let model = log_action(model, turn_name(model.turn) <> "のターン開始。")
  draw_turn_card(model)
}

fn draw_turn_card(model: Model) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      log_action(
        model,
        turn_name(model.turn) <> "は山札が空のため、ターン開始時に引けませんでした。",
      )

    [drawn_card, ..rest] -> {
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      log_action(
        model,
        turn_name(model.turn) <> "がターン開始時に" <> land_name(drawn_card) <> "を引きました。",
      )
    }
  }
}

fn finalize_after_action(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> model
  }
}

fn log_and_prompt(model: Model, entry: String, prompt: Prompt) -> Model {
  let model = log_action(model, entry)
  Model(..model, prompt: prompt)
}

fn winner(model: Model) -> Winner {
  case has_all_five(model.player_one.battlefield) {
    True -> HasWinner(PlayerOne)
    False ->
      case has_all_five(model.player_two.battlefield) {
        True -> HasWinner(PlayerTwo)
        False -> NoWinner
      }
  }
}

fn has_all_five(cards: List(Land)) -> Bool {
  contains_land(cards, Plains)
    && contains_land(cards, Island)
    && contains_land(cards, Swamp)
    && contains_land(cards, Mountain)
    && contains_land(cards, Forest)
}

fn battlefield_exists(model: Model) -> Bool {
  list.length(model.player_one.battlefield) + list.length(model.player_two.battlefield) > 0
}

fn has_counter_cost(cards: List(Land)) -> Bool {
  contains_land(cards, Island) && count_non_island(cards) > 0
}

fn count_non_island(cards: List(Land)) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == Island {
        True -> count_non_island(rest)
        False -> 1 + count_non_island(rest)
      }
  }
}

fn contains_land(cards: List(Land), target: Land) -> Bool {
  case cards {
    [] -> False
    [card, ..rest] ->
      case card == target {
        True -> True
        False -> contains_land(rest, target)
      }
  }
}

fn remove_first(cards: List(Land), target: Land) -> #(List(Land), PickResult(Land)) {
  case cards {
    [] -> #([], NotPicked)
    [card, ..rest] ->
      case card == target {
        True -> #(rest, Picked(card))
        False -> {
          let #(new_rest, pick) = remove_first(rest, target)
          #([card, ..new_rest], pick)
        }
      }
  }
}

fn remove_at(cards: List(Land), target_index: Int, current_index: Int) -> #(List(Land), PickResult(Land)) {
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

fn log_action(model: Model, entry: String) -> Model {
  Model(..model, log: [entry, ..model.log])
}

fn draw_opening_hand(player: Player, count: Int) -> Player {
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

fn new_player(turn: Turn) -> Player {
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

fn repeated_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  case times {
    0 -> acc
    _ -> repeated_deck(cycle, times - 1, append_list(cycle, acc))
  }
}

fn append_list(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    [card, ..rest] -> [card, ..append_list(rest, acc)]
  }
}
