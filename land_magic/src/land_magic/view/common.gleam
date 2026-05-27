import gleam/int
import gleam/list
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{type Player, type Prompt, type Msg, ChoosePlay, DrawTurnCard, CounterWindow, CounterSelecting, ChoosePlainsTarget, ChooseSwampTarget, ChooseMountainTarget, ChooseForestDraw, EndTurnReady, GameOver}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// 概要: 画面の操作ボタンを作ります。
/// 引数: `kind` に見た目の種類を渡します。
/// 引数: `label` に表示文字を渡します。
/// 引数: `message` に押した時の動作を渡します。
/// 引数: `enabled` に有効/無効を渡します。
/// 戻り値: クリック可能なボタン要素を返します。
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

/// 概要: 数値や短い情報を見やすいカードで表示します。
/// 引数: `label` に項目名を渡します。
/// 引数: `value` に表示したい値を渡します。
/// 戻り値: 統計カードの要素を返します。
pub fn stat_card(label: String, value: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("stat-card", True)])],
    [
      html.span([attribute.classes([#("stat-label", True)])], [html.text(label)]),
      html.strong([], [html.text(value)]),
    ],
  )
}

/// 概要: プレイヤーの各領域の枚数を1行でまとめます。
/// 引数: `player` に対象プレイヤーを渡します。
/// 戻り値: 山札・手札・戦場・墓地の枚数をまとめた文字列を返します。
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

/// 概要: プレイヤーパネルの活性状態に応じた CSS クラス名を返します。
/// 引数: `active` に手番中かどうかを渡します。
/// 戻り値: 状態に応じたクラス名を返します。
pub fn player_panel_class(active: Bool) -> String {
  case active {
    True -> "panel-active"
    False -> "panel-idle"
  }
}

/// 概要: 上段・下段で使うボード用クラス名を返します。
/// 引数: `top` に上側パネルかどうかを渡します。
/// 戻り値: ボード位置に応じたクラス名を返します。
pub fn player_board_class(top: Bool) -> String {
  case top {
    True -> "top-board"
    False -> "bottom-board"
  }
}

/// 概要: プレイヤーパネルの上下位置を表す CSS クラス名を返します。
/// 引数: `top` に上側パネルかどうかを渡します。
/// 戻り値: 位置に応じたクラス名を返します。
pub fn player_panel_position_class(top: Bool) -> String {
  case top {
    True -> "player-panel-top"
    False -> "player-panel-bottom"
  }
}

/// 概要: 画面状態を短い名前に変換します。
/// 引数: `prompt` に現在の操作状態を渡します。
/// 戻り値: 一覧表示やステータス表示向けの短い名前を返します。
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

/// 概要: 現在の操作について、初心者向けの説明文を返します。
/// 引数: `prompt` に現在の操作状態を渡します。
/// 戻り値: 何をすればよいかを説明する文章を返します。
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
