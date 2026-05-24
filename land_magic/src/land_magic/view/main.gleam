import land_magic/model/types.{type Model, type Msg, PlayerOne, PlayerTwo, ChoosePlay, ChooseForestDraw, DrawTurnCard}
import land_magic/view/hero
import land_magic/view/player_panel
import land_magic/view/sidebar
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn render(model: Model) -> Element(Msg) {
  let play_enabled = case model.prompt {
    ChoosePlay -> True
    _ -> False
  }

  let draw_enabled = case model.prompt {
    DrawTurnCard -> True
    ChooseForestDraw(_) -> True
    _ -> False
  }

  html.div(
    [attribute.classes([#("app-shell", True)])],
    [
      hero.hero(model),
      html.main(
        [attribute.classes([#("board-layout", True)])],
        [
          html.div(
            [attribute.classes([#("playfield", True)])],
            [
              player_panel.player_panel(
                model.player_two,
                PlayerTwo,
                model.turn == PlayerTwo,
                True,
                model.prompt,
                play_enabled,
                draw_enabled,
              ),
              player_panel.player_panel(
                model.player_one,
                PlayerOne,
                model.turn == PlayerOne,
                False,
                model.prompt,
                play_enabled,
                draw_enabled,
              ),
            ],
          ),
          sidebar.sidebar(model.log),
        ],
      ),
    ],
  )
}
