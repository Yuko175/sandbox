import gleam/int
import gleam/list
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{type Player, type Prompt, type Msg, ChoosePlay, DrawTurnCard, CounterWindow, CounterSelecting, ChoosePlainsTarget, ChooseSwampTarget, ChooseMountainTarget, ChooseForestDraw, EndTurnReady, GameOver}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn button_control(kind: String, label: String, message: Msg, enabled: Bool) -> Element(Msg) {
  html.button(
    [
      attribute.classes([#("action-button", True), #(kind, True)]),
      attribute.disabled(!enabled),
      event.on_click(message),
    ],
    [html.text(label)],
  )
}

pub fn stat_card(label: String, value: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("stat-card", True)])],
    [
      html.span([attribute.classes([#("stat-label", True)])], [html.text(label)]),
      html.strong([], [html.text(value)]),
    ],
  )
}

pub fn zone_summary(player: Player) -> String {
  "山札 "
    <> int.to_string(list.length(player.deck))
    <> " • 手札 "
    <> int.to_string(list.length(player.hand))
    <> " • 戦場 "
    <> int.to_string(list.length(player.battlefield))
    <> " • 墓地 "
    <> int.to_string(list.length(player.graveyard))
}

pub fn player_panel_class(active: Bool) -> String {
  case active {
    True -> "panel-active"
    False -> "panel-idle"
  }
}

pub fn player_board_class(top: Bool) -> String {
  case top {
    True -> "top-board"
    False -> "bottom-board"
  }
}

pub fn player_panel_position_class(top: Bool) -> String {
  case top {
    True -> "player-panel-top"
    False -> "player-panel-bottom"
  }
}

pub fn prompt_name(prompt: Prompt) -> String {
  case prompt {
    DrawTurnCard -> "山札を引く"
    ChoosePlay -> "プレイ"
    CounterWindow(_) -> "打ち消し"
    CounterSelecting(_, _) -> "打ち消し選択"
    ChoosePlainsTarget(_) -> "平地"
    ChooseSwampTarget(_) -> "沼"
    ChooseMountainTarget(_) -> "山"
    ChooseForestDraw(_) -> "森"
    EndTurnReady -> "終了待ち"
    GameOver(winner) -> turn_name(winner) <> "の勝利"
  }
}

pub fn prompt_detail(prompt: Prompt) -> String {
  case prompt {
    DrawTurnCard -> "山札をクリックして1枚引いてください。"
    ChoosePlay -> "手札から1枚を選んでください。"
    CounterWindow(_) -> "『打ち消し』か『打ち消しパス』を選んでください。"
    CounterSelecting(_, _) -> "島1枚と別の1枚を選んでください。"
    ChoosePlainsTarget(card) ->
      land_name(card) <> "の効果です。自分の墓地から1枚を選んで手札に戻してください。"
    ChooseSwampTarget(card) ->
      land_name(card) <> "の効果です。自分の手札から1枚を選んで墓地に置いてください。"
    ChooseMountainTarget(card) ->
      land_name(card) <> "の効果です。戦場から1枚を選んで破壊してください。"
    ChooseForestDraw(card) ->
      land_name(card) <> "の効果です。山札から1枚引いてください。"
    EndTurnReady -> "『ターン終了』を押してください。"
    GameOver(winner) -> turn_name(winner) <> "の勝利です。"
  }
}
