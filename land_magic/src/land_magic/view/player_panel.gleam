import land_magic/game/rules
import land_magic/model/types.{type Player, type Prompt, type Msg, type Turn, CounterWindow, CounterSelecting, BeginCounterSelection, PassCounter, FinishTurn}
import land_magic/view/common
import land_magic/view/zones
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn player_panel(player: Player, turn: Turn, active: Bool, top: Bool, prompt: Prompt, can_play: Bool, can_draw: Bool) -> Element(Msg) {
  let counter_prompt_enabled = case prompt {
    CounterWindow(_) -> True
    CounterSelecting(_, _) -> True
    _ -> False
  }

  let can_counter = active && counter_prompt_enabled && rules.has_counter_cost(player.hand)
  let can_pass_counter = active && counter_prompt_enabled

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
      case active {
        True ->
          html.p(
            [attribute.classes([#("panel-hint", True)])],
            [html.text(common.prompt_detail(prompt))],
          )

        False -> html.text("")
      },
      html.div([attribute.classes([#("zone-grid", True), #(common.player_board_class(top), True)])], [
        zones.deck_zone(player.deck, active && can_draw),
        zones.hand_zone(player.hand, active, prompt, can_play),
        zones.graveyard_zone(player.graveyard, active, prompt),
        zones.battlefield_zone(player.battlefield, prompt, active, turn),
        html.div([attribute.classes([#("zone-grid-actions", True)])], [
          common.button_control("secondary", "打ち消し", BeginCounterSelection, can_counter),
          common.button_control("secondary", "打ち消しパス", PassCounter, can_pass_counter),
          common.button_control("primary", "ターン終了", FinishTurn, True),
        ]),
      ]),
    ],
  )
}
