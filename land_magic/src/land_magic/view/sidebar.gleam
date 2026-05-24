import land_magic/model/types.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

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
