import land_magic/game/rules
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Player,
  EndTurnReady,
  ChooseSwampTarget,
  Model,
  Picked,
}
import land_magic/state/players.{opponent_player, set_opponent_player}

pub fn resolve_on_play(model: Model, card: Land) -> Model {
  case opponent_player(model).hand {
    [] ->
      rules.finalize_after_action(
        rules.log_and_prompt(
          model,
          turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、相手の手札がありません。",
          EndTurnReady,
        ),
      )

    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseSwampTarget(card),
      )
  }
}

pub fn resolve_target(model: Model, index: Int) -> Model {
  let opponent = opponent_player(model)

  case rules.remove_at(opponent.hand, index, 0) {
    #(new_hand, Picked(discarded_card)) -> {
      let opponent = Player(..opponent, hand: new_hand, graveyard: [discarded_card, ..opponent.graveyard])
      let model = set_opponent_player(model, opponent)
      let model = rules.log_action(
        model,
        turn_name(other_turn(model.turn)) <> "が沼で" <> land_name(discarded_card) <> "を捨てました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}
