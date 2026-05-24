import land_magic/game/rules
import land_magic/game/setup
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Model,
  Picked,
  EndTurnReady,
  ChooseForestDraw,
}
import land_magic/state/players.{current_player, set_current_player}

pub fn resolve_on_play(model: Model, card: Land) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      rules.finalize_after_action(
        rules.log_and_prompt(
          model,
          turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、山札が空です。",
          EndTurnReady,
        ),
      )

    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseForestDraw(card),
      )
  }
}

pub fn resolve_draw(model: Model) -> Model {
  let current = current_player(model)

  case setup.draw_random_card(current) {
    #(updated_current, Picked(drawn_card)) -> {
      let model = set_current_player(model, updated_current)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が森で" <> land_name(drawn_card) <> "を引きました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ ->
      rules.finalize_after_action(
        rules.log_and_prompt(model, turn_name(model.turn) <> "は山札が空で引けませんでした。", EndTurnReady),
      )
  }
}