import land_magic/game/rules
import land_magic/game/setup
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Model,
  Player,
  EndTurnReady,
  CounterSelecting,
  ChoosePlay,
  GameOver,
  HasWinner,
  NoWinner,
  Picked,
  Island,
}
import land_magic/state/players.{current_player, set_current_player}

pub fn begin_counter_selection(model: Model, card: Land) -> Model {
  Model(..model, prompt: CounterSelecting(card, []))
}

pub fn select_counter_card(model: Model, card: Land, index: Int) -> Model {
  case model.prompt {
    CounterSelecting(_, selected) ->
      case selected {
        [] -> Model(..model, prompt: CounterSelecting(card, [index]))

        [first_index, ..] ->
          case first_index == index {
            True -> model
            False -> resolve_counter_selection(model, card, first_index, index)
          }
      }

    _ -> model
  }
}

pub fn pass_counter(model: Model, card: Land) -> Model {
  let model = rules.log_action(model, turn_name(model.turn) <> "は打ち消しをパスしました。")
  let model = Model(..model, turn: other_turn(model.turn))
  resolve_on_play(model, card)
}

pub fn resolve_on_play(model: Model, card: Land) -> Model {
  rules.finalize_after_action(
    rules.log_and_prompt(
      model,
      turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
      EndTurnReady,
    ),
  )
}

fn resolve_counter_selection(model: Model, card: Land, first_index: Int, second_index: Int) -> Model {
  let defender = current_player(model)
  let low_index = case first_index < second_index {
    True -> first_index
    False -> second_index
  }
  let high_index = case first_index < second_index {
    True -> second_index
    False -> first_index
  }

  case rules.remove_at(defender.hand, high_index, 0) {
    #(hand_after_high, Picked(high_card)) ->
      case rules.remove_at(hand_after_high, low_index, 0) {
        #(final_hand, Picked(low_card)) ->
          case high_card == Island || low_card == Island {
            True -> {
              let discarded_card = case high_card == Island {
                True -> low_card
                False -> high_card
              }
              let defender = Player(
                ..defender,
                hand: final_hand,
                graveyard: [discarded_card, high_card, ..defender.graveyard],
              )
              let model = set_current_player(model, defender)
              let model = rules.log_action(
                model,
                turn_name(model.turn)
                  <> "が島と"
                  <> land_name(discarded_card)
                  <> "を捨て、"
                  <> land_name(card)
                  <> "を打ち消しました。",
              )

              finish_counter(Model(..model, turn: other_turn(model.turn)))
            }

            False ->
              rules.log_action(
                Model(..model, prompt: CounterSelecting(card, [])),
                "打ち消しには島と別の1枚を選んでください。",
              )
          }

        _ -> Model(..model, prompt: CounterSelecting(card, []))
      }

    _ -> Model(..model, prompt: CounterSelecting(card, []))
  }
}

fn finish_counter(model: Model) -> Model {
  case rules.winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> {
      let next_turn = other_turn(model.turn)
      let model = Model(
        ..model,
        turn: next_turn,
        prompt: ChoosePlay,
        turn_number: model.turn_number + 1,
      )

      let model = Model(..model, log: [turn_name(model.turn) <> "のターン開始。", ..model.log])
      setup.draw_turn_card(model)
    }
  }
}
