import gleam/int
import land_magic/model/domain.{land_class, land_name}
import land_magic/model/types.{type Land, type Msg, PlayCard, SelectCounterCard, ReturnFromGraveyard, DiscardOpponentCard, DestroyFromBattlefield, type Turn, Plains, Island, Swamp, Mountain, Forest}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// 概要: カードを静的表示用の要素に変換します。
/// 引数: `cards` に表示したい土地カード一覧を渡します。
/// 戻り値: クリックできないカード要素の一覧を返します。
pub fn render_static_cards(cards: List(Land)) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_chip(card), ..render_static_cards(rest)]
  }
}

/// 概要: 手札をプレイ可能なボタンとして表示します。
/// 引数: `cards` に手札を渡します。
/// 引数: `index` に先頭からの位置を渡します。
/// 戻り値: プレイ用ボタンの一覧を返します。
pub fn render_play_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, PlayCard(index), False),
      ..render_play_hand_cards(rest, index + 1)
    ]
  }
}

/// 概要: 打ち消し選択用に手札を表示します。
/// 引数: `cards` に手札を渡します。
/// 引数: `index` に位置を渡します。
/// 引数: `selected` に選択済みの位置一覧を渡します。
/// 戻り値: 打ち消しで選べる手札ボタンの一覧を返します。
pub fn render_counter_hand_cards(cards: List(Land), index: Int, selected: List(Int)) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, SelectCounterCard(index), index_in(selected, index)),
      ..render_counter_hand_cards(rest, index + 1, selected)
    ]
  }
}

/// 概要: 墓地から手札へ戻すカード選択用に表示します。
/// 引数: `cards` に手札を渡します。
/// 引数: `index` に位置を渡します。
/// 戻り値: 戻し先として選べる手札ボタンの一覧を返します。
pub fn render_return_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, ReturnFromGraveyard(index), False),
      ..render_return_hand_cards(rest, index + 1)
    ]
  }
}

/// 概要: 相手の手札を捨てるための選択肢を表示します。
/// 引数: `cards` に手札を渡します。
/// 引数: `index` に位置を渡します。
/// 戻り値: 捨てる対象として選べる手札ボタンの一覧を返します。
pub fn render_discard_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, DiscardOpponentCard(index), False),
      ..render_discard_hand_cards(rest, index + 1)
    ]
  }
}

/// 概要: 戦場のカードを破壊対象として表示します。
/// 引数: `cards` に戦場のカードを渡します。
/// 引数: `index` に位置を渡します。
/// 引数: `owner` に対象プレイヤーの手番を渡します。
/// 戻り値: 破壊対象として選べるカードボタンの一覧を返します。
pub fn render_destroy_battlefield_cards(cards: List(Land), index: Int, owner: Turn) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, DestroyFromBattlefield(owner, index), False),
      ..render_destroy_battlefield_cards(rest, index + 1, owner)
    ]
  }
}

/// 概要: 墓地から戻すためのカードボタン一覧を作ります。
/// 引数: `cards` に墓地の一覧を渡します。
/// 引数: `enabled` に有効かどうかを渡します。
/// 戻り値: 墓地のカードごとの選択ボタン一覧を返します。
pub fn render_graveyard_buttons(cards: List(Land), enabled: Bool) -> List(Element(Msg)) {
  graveyard_buttons(cards, [Plains, Island, Swamp, Mountain, Forest], enabled)
}

/// 概要: 1枚の土地カードを静的表示します。
/// 引数: `land` に表示したい土地カードを渡します。
/// 戻り値: カード画像を含む表示要素を返します。
pub fn land_chip(land: Land) -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #(land_class(land), True)]), attribute.title(land_name(land))],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
    ],
  )
}

/// 概要: 裏向きのカードを表示します。
/// 引数: この関数は追加の引数を受け取りません。
/// 戻り値: 伏せカードの表示要素を返します。
pub fn facedown_chip() -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #("facedown", True)]), attribute.title("伏せカード")],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(back_image_src()), attribute.alt("伏せカード")]),
    ],
  )
}

/// 概要: 手札用のクリック可能なカードボタンを作ります。
/// 引数: `land` にカードを渡します。
/// 引数: `message` に押した時の動作を渡します。
/// 引数: `selected` に選択状態を渡します。
/// 戻り値: 手札カードボタンの要素を返します。
pub fn hand_card_button(land: Land, message: Msg, selected: Bool) -> Element(Msg) {
  let selected_class = case selected {
    True -> #( "selected", True )
    False -> #( "selected", False )
  }

  let classes = [#("card-chip", True), #("card-chip-button", True), #(land_class(land), True), #("with-image", True), selected_class]

  html.button(
    [
      attribute.classes(classes),
      attribute.title(land_name(land)),
      event.on_click(message),
    ],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
    ],
  )
}

/// 概要: 墓地の候補カードを順番にボタンへ変換します。
/// 引数: `cards` に墓地の内容を渡します。
/// 引数: `targets` に表示したいカード種を渡します。
/// 引数: `enabled` に有効化フラグを渡します。
/// 戻り値: 墓地選択用のボタン一覧を返します。
fn graveyard_buttons(cards: List(Land), targets: List(Land), enabled: Bool) -> List(Element(Msg)) {
  case targets {
    [] -> []
    [target, ..rest] ->
      [
        graveyard_card_button(
          target,
          land_count(cards, target),
          ReturnFromGraveyard(first_index_of(cards, target, 0)),
          enabled && land_count(cards, target) > 0,
        ),
        ..graveyard_buttons(cards, rest, enabled),
      ]
  }
}

/// 概要: 墓地の1種類を選ぶボタンを作ります。
/// 引数: `land` にカード種を渡します。
/// 引数: `count` に枚数を渡します。
/// 引数: `message` に押した時の動作を渡します。
/// 引数: `enabled` に有効化フラグを渡します。
/// 戻り値: 墓地カードの選択ボタンを返します。
fn graveyard_card_button(land: Land, count: Int, message: Msg, enabled: Bool) -> Element(Msg) {
  html.button(
    [
      attribute.classes([
        #("card-chip", True),
        #("card-chip-button", True),
        #("with-image", True),
        #("graveyard-card-button", True),
        #(land_class(land), True),
      ]),
      attribute.title(land_name(land)),
      attribute.disabled(!enabled),
      // keep on_click even if disabled; disabled prevents activation
      event.on_click(message),
    ],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
      html.span([], [html.text("×" <> int.to_string(count))]),
    ],
  )
}

/// 概要: 指定した種類のカード枚数を数えます。
/// 引数: `cards` にカード一覧を渡します。
/// 引数: `target` に数えたいカード種を渡します。
/// 戻り値: 対象カードの枚数を返します。
fn land_count(cards: List(Land), target: Land) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == target {
        True -> 1 + land_count(rest, target)
        False -> land_count(rest, target)
      }
  }
}

/// 概要: 指定した種類のカードが最初に見つかる位置を返します。
/// 引数: `cards` にカード一覧を渡します。
/// 引数: `target` に探すカード種を渡します。
/// 引数: `index` に再帰用の現在位置を渡します。
/// 戻り値: 最初に見つかった位置を返します。
fn first_index_of(cards: List(Land), target: Land, index: Int) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == target {
        True -> index
        False -> first_index_of(rest, target, index + 1)
      }
  }
}

/// 概要: 土地カードに対応する画像パスを返します。
/// 引数: `land` にカード種を渡します。
/// 戻り値: 画像ファイルのパスを返します。
fn image_src(land: Land) -> String {
  case land_class(land) {
    "plains" -> "images/plain.jpg"
    "island" -> "images/island.jpg"
    "swamp" -> "images/swamp.jpg"
    "mountain" -> "images/mountain.jpg"
    "forest" -> "images/forest.jpg"
    _ -> back_image_src()
  }
}

/// 概要: 裏向きカード画像のパスを返します。
/// 引数: この関数は追加の引数を受け取りません。
/// 戻り値: 裏面画像のファイルパスを返します。
fn back_image_src() -> String {
  "images/back.jpg"
}

/// 概要: 選択済みリストに指定位置が含まれるかを調べます。
/// 引数: `selected` に選択済みの位置一覧を渡します。
/// 引数: `index` に確認したい位置を渡します。
/// 戻り値: 含まれていれば `True` を返します。
fn index_in(selected: List(Int), index: Int) -> Bool {
  case selected {
    [] -> False
    [i, ..rest] ->
      case i == index {
        True -> True
        False -> index_in(rest, index)
      }
  }
}
