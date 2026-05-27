import gleam/int
import land_magic/model/domain.{turn_name}
import land_magic/model/types.{type Model, type Msg}
import land_magic/view/common
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 概要: 画面上部の概要エリアを表示します。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 戻り値: タイトル、説明、ステータスカードをまとめた要素を返します。
pub fn hero(model: Model) -> Element(Msg) {
  html.header(
    [attribute.classes([#("hero", True)])],
    [
      html.div([attribute.classes([#("hero-copy", True)])], [
        html.p(
          [attribute.classes([#("eyebrow", True)])],
          [html.text("ランドマジック")],
        ),
        html.h1([], [html.text("手札公開・手動進行・五色の土地で勝利")]),
        html.p(
          [attribute.classes([#("hero-text", True)])],
          [
            html.text(
              "Lustre SPAで再現したカジュアルなランドマジック。基本土地のみ、手札公開、すべて手動操作。",
            ),
          ],
        ),
      ]),
      html.div(
        [attribute.classes([#("hero-stats", True)])],
        [
          common.stat_card("ターン", int.to_string(model.turn_number)),
          common.stat_card("手番", turn_name(model.turn)),
          common.stat_card("状態", common.prompt_name(model.prompt)),
        ],
      ),
    ],
  )
}
