import land_magic/model/types.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 概要: サイドバーにアクションログを表示します。
/// 引数: `log` に表示したいログ一覧を渡します。
/// 戻り値: ログ領域を含むサイドバー要素を返します。
pub fn sidebar(log: List(String)) -> Element(Msg) {
  html.aside(
    [attribute.classes([#("sidebar", True)])],
    [
      html.section([attribute.classes([#("settings-panel", True), #("empty-settings", True)])], []),
      html.section(
        [attribute.classes([#("panel", True), #("log-panel", True)])],
        [
          html.div([attribute.classes([#("panel-head", True)])], [
            html.h2([], [html.text("アクションログ")]),
            html.p([], [html.text("最新の行動が上に表示されます。")]),
          ]),
          html.div([attribute.classes([#("log-list", True)])], render_log_items(log, 10)),
        ],
      ),
    ],
  )
}

/// 概要: ログを上から順に限界数まで要素に変換します。
/// 引数: `log` にログ一覧を渡します。
/// 引数: `limit` に表示件数の上限を渡します。
/// 戻り値: 表示用のログ要素一覧を返します。
fn render_log_items(log: List(String), limit: Int) -> List(Element(Msg)) {
  case limit {
    0 -> []
    _ ->
      case log {
        [] -> []
        [entry, ..rest] -> [
          html.div([attribute.classes([#("log-entry", True)])], [html.text(entry)]),
          ..render_log_items(rest, limit - 1)
        ]
      }
  }
}
