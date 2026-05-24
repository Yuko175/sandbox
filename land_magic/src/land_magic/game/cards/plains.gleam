import land_magic/game/rules
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Player,
  EndTurnReady,
  ChoosePlainsTarget,
  Model,
  Picked,
}
import land_magic/state/players.{current_player, set_current_player}

pub fn resolve_on_play(model: Model, card: Land) -> Model {
  let current = current_player(model)

  case current.graveyard {
    [] ->
      rules.finalize_after_action(
        rules.log_and_prompt(
          model,
          turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、墓地に対象がありません。",
          EndTurnReady,
        ),
      )

    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChoosePlainsTarget(card),
      )
  }
}

pub fn resolve_target(model: Model, index: Int) -> Model {
  let current = current_player(model)

  case rules.remove_at(current.graveyard, index, 0) {
    #(new_graveyard, Picked(returned_card)) -> {
      let current = Player(..current, graveyard: new_graveyard, hand: [returned_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が平地で" <> land_name(returned_card) <> "を回収しました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}
