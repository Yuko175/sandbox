import land_magic/game/rules
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  type Turn,
  Player,
  EndTurnReady,
  ChooseMountainTarget,
  Model,
  Picked,
}
import land_magic/state/players.{player_by_turn, set_player}

pub fn resolve_on_play(model: Model, card: Land) -> Model {
  case rules.battlefield_exists(model) {
    True ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseMountainTarget(card),
      )
    False ->
      rules.finalize_after_action(
        rules.log_and_prompt(
          model,
          turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、戦場に対象がありません。",
          EndTurnReady,
        ),
      )
  }
}

pub fn resolve_target(model: Model, owner: Turn, index: Int) -> Model {
  let target_player = player_by_turn(model, owner)

  case rules.remove_at(target_player.battlefield, index, 0) {
    #(new_battlefield, Picked(destroyed_card)) -> {
      let target_player = Player(
        ..target_player,
        battlefield: new_battlefield,
        graveyard: [destroyed_card, ..target_player.graveyard],
      )
      let model = set_player(model, owner, target_player)
      let model = rules.log_action(
        model,
        turn_name(model.turn)
          <> "が山で"
          <> turn_name(owner)
          <> "の"
          <> land_name(destroyed_card)
          <> "を破壊しました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}
