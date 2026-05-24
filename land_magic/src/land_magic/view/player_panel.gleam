import land_magic/model/types.{type Player, type Prompt, type Msg}
import land_magic/view/common
import land_magic/view/zones
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn player_panel(player: Player, active: Bool, top: Bool, prompt: Prompt, can_play: Bool, can_draw: Bool) -> Element(Msg) {
  html.section(
    [
      attribute.classes([
        #("panel", True),
        #("player-panel", True),
        #(common.player_panel_class(active), True),
        #(common.player_panel_position_class(top), True),
      ]),
    ],
    [
      html.div([attribute.classes([#("panel-head", True)])], [
        html.div([attribute.classes([#("title-row", True)])], [
          html.h2([], [html.text(player.name)]),
          case active {
            True ->
              html.span(
                [attribute.classes([#("badge", True), #("badge-active", True)])],
                [html.text("手番中")],
              )
            False -> html.span([attribute.classes([#("badge", True)])], [html.text("待機中")])
          },
        ]),
        html.p([], [html.text(common.zone_summary(player))]),
      ]),
      html.div([attribute.classes([#("zone-grid", True), #(common.player_board_class(top), True)])], [
        zones.deck_zone(player.deck, active && can_draw),
        zones.hand_zone(player.hand, active, prompt, can_play),
        zones.zone_view("墓地", player.graveyard, "graveyard-zone"),
        zones.zone_view("戦場", player.battlefield, "battlefield-zone"),
      ]),
    ],
  )
}
