import gleam/float
import gleam/int
import gleam/string
import lustre
import lustre/element.{type Element, text}
import lustre/element/html.{
  button,
  div,
  h1,
  input,
  p,
}
import lustre/attribute
import lustre/event.{on_click, on_input}
import lustre/effect

@external(javascript, "./ffi.mjs", "start_interval")
fn start_interval(cb: fn() -> Nil, ms: Int) -> Nil

@external(javascript, "./ffi.mjs", "stop_interval")
fn stop_interval() -> Nil

@external(javascript, "./ffi.mjs", "start_timeout")
fn start_timeout(cb: fn() -> Nil, ms: Int) -> Nil

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    timer: Float,
    target: Float,
    seconds_input: String,
    centis_input: String,
    ready: Bool,
    running: Bool,
    hidden: Bool,
    result: String,
  )
}

type Msg {
  Start
  Stop
  Reset
  Tick
    SetSecondsInput(String)
    SetCentisInput(String)
    HideTimer
  }
  
  fn init(_flags) -> #(Model, effect.Effect(Msg)) {
    #(
      Model(
        timer: 0.0,
        target: 0.0,
        seconds_input: "",
        centis_input: "",
        ready: False,
        running: False,
        hidden: False,
        result: "",
      ),
      effect.none(),
    )
  }
  
  fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
    case msg {
      Start -> {
        let secs = parse_int_clamped(model.seconds_input, 0, 999)
        let centis = parse_int_clamped(model.centis_input, 0, 99)
        let target = int.to_float(secs) +. { int.to_float(centis) /. 100.0 }
  
        let is_valid = target >=. 3.0 && target <=. 59.99
  
        case is_valid {
          True -> {
            let new_model =
              Model(
                ..model,
                timer: 0.0,
                target: target,
                running: True,
                hidden: False,
                result: "",
              )
  
            #(
              new_model,
              effect.batch([every_10ms(), hide_after_2sec()]),
            )
          }
          False -> {
            #(
              Model(..model, result: "エラー: 3.00秒から59.99秒の間で設定してください"),
              effect.none(),
            )
          }
        }
      }
  
      Tick -> {
        case model.running {
          True -> {
            #(Model(..model, timer: model.timer +. 0.01), effect.none())
          }
          False -> #(model, effect.none())
        }
      }
  
      HideTimer -> {
        case model.running {
          True -> #(Model(..model, hidden: True), effect.none())
          False -> #(model, effect.none())
        }
      }
  
      Stop -> {
        let diff = float.absolute_value(model.timer -. model.target)
  
        let judgement =
          case diff <=. 0.10 {
            True -> "PERFECT!!"
            False ->
              case diff <=. 0.30 {
                True -> "GOOD!"
                False -> "MISS..."
              }
          }
  
        #(
          Model(
            ..model,
            running: False,
            hidden: False,
            result: judgement
              <> " 目標:"
              <> float_to_2digit(model.target)
              <> "秒 / 結果:"
              <> float_to_2digit(model.timer)
              <> "秒",
          ),
          effect.from(fn(_dispatch) { stop_interval() }),
        )
      }
  
      Reset -> {
        #(
          Model(
            ..model,
            timer: 0.0,
            running: False,
            hidden: False,
            result: "",
          ),
          effect.from(fn(_dispatch) { stop_interval() }),
        )
      }
  
      SetSecondsInput(value) -> {
        let ready = string.trim(value) != "" || string.trim(model.centis_input) != ""
        #(Model(..model, seconds_input: value, ready: ready), effect.none())
      }
  
      SetCentisInput(value) -> {
        let ready = string.trim(model.seconds_input) != "" || string.trim(value) != ""
        #(Model(..model, centis_input: value, ready: ready), effect.none())
      }
    }
  }

// fn view(model: Model) -> Element(Msg) {
//   div(
//     [
//       attribute.style("font-family", "sans-serif"),
//       attribute.style("padding", "24px"),
//     ],
//     [
//       h1([], [text("タイマー")]),

//       p([], [
//         text("目標(3〜59秒): "),
//         input([
//           attribute.type_("text"),
//           attribute.placeholder("3〜59"),
//           attribute.value(model.seconds_input),
//           on_input(SetSecondsInput),
//         ]),
//         text(" 秒 "),
//         input([
//           attribute.type_("text"),
//           attribute.placeholder("00〜99"),
//           attribute.value(model.centis_input),
//           on_input(SetCentisInput),
//         ]),

//         button([on_click(ConfirmTarget)], [text("決定")]),
//       ]),

//       p([], [
//         text("タイマー"),
//       ]),

//       case model.hidden {
//         True -> p([], [text("？？？？")])
//         False -> p([], [text(float_to_2digit(model.timer) <> " 秒")])
//       },

//       p([], [text("判定: " <> model.result)]),

//       div([], [
//         button(
//           [
//             on_click(Start),
//             attribute.disabled(model.running || !model.ready),
//           ],
//           [text("スタート")],
//         ),

//         button(
//           [
//             on_click(Stop),
//           ],
//           [text("ストップ")],
//         ),

//         button(
//           [
//             on_click(Reset),
//           ],
//           [text("リセット")],
//         ),
//       ]),
//     ],
//   )
// }

// fn float_to_2digit(value: Float) -> String {
//   let total = float.round(value *. 100.0)

//   let secs = total / 100
//   let centis = total % 100

//   two_digits(secs)
//     <> "."
//     <> two_digits(centis)
// }

// fn every_10ms() -> effect.Effect(Msg) {
//   effect.from(fn(dispatch) { start_interval(fn() { dispatch(Tick) }, 10) })
// }

// fn hide_after_2sec() -> effect.Effect(Msg) {
//   effect.from(fn(dispatch) { start_timeout(fn() { dispatch(HideTimer) }, 2000) })
// }

// fn parse_int_clamped(value: String, minimum: Int, maximum: Int) -> Int {
//   let parsed =
//     case int.parse(string.trim(value)) {
//       Ok(v) -> v
//       Error(_) -> minimum
//     }

//   case parsed < minimum {
//     True -> minimum
//     False ->
//       case parsed > maximum {
//         True -> maximum
//         False -> parsed
//       }
//   }
// }

// fn two_digits(value: Int) -> String {
//   case value < 10 {
//     True -> "0" <> int.to_string(value)
//     False -> int.to_string(value)
//   }
// }



fn view(model: Model) -> Element(Msg) {
  div(
    [
      attribute.style("font-family", "Inter, sans-serif"),
      attribute.style("background", "#f5f7fb"),
      attribute.style("min-height", "100vh"),
      attribute.style("padding", "40px"),
      attribute.style("color", "#1f2937"),
    ],
    [
      div(
        [
          attribute.style("max-width", "720px"),
          attribute.style("margin", "0 auto"),
          attribute.style("background", "white"),
          attribute.style("padding", "32px"),
          attribute.style("border-radius", "16px"),
          attribute.style("box-shadow", "0 2px 8px rgba(0,0,0,0.08)"),
        ],
        [
          h1(
            [
              attribute.style("margin-bottom", "24px"),
              attribute.style("font-size", "28px"),
            ],
            [text("Reaction Timer")],
          ),

          p(
            [
              attribute.style("font-size", "14px"),
              attribute.style("color", "#6b7280"),
            ],
            [text("ターゲット時間を設定してください")],
          ),

          case string.starts_with(model.result, "エラー:") {
            True ->
              p(
                [
                  attribute.style("color", "#ef4444"),
                  attribute.style("font-size", "14px"),
                  attribute.style("margin-top", "4px"),
                ],
                [text(model.result)],
              )
            False -> element.none()
          },

          div(
            [
              attribute.style("display", "flex"),
              attribute.style("gap", "12px"),
              attribute.style("margin-top", "16px"),
              attribute.style("align-items", "center"),
            ],
            [
              input([
                attribute.type_("text"),
                attribute.value(model.seconds_input),
                attribute.placeholder("00"),
                on_input(SetSecondsInput),
                attribute.style("padding", "10px"),
                attribute.style("width", "100px"),
                attribute.style("border", "1px solid #d1d5db"),
                attribute.style("border-radius", "8px"),
              ]),
              text("秒"),

              input([
                attribute.type_("text"),
                attribute.value(model.centis_input),
                attribute.placeholder("00"),
                on_input(SetCentisInput),
                attribute.style("padding", "10px"),
                attribute.style("width", "80px"),
                attribute.style("border", "1px solid #d1d5db"),
                attribute.style("border-radius", "8px"),
              ]),
            ],
          ),

          div(
            [
              attribute.style("margin-top", "40px"),
              attribute.style("padding", "32px"),
              attribute.style("background", "#111827"),
              attribute.style("border-radius", "16px"),
              attribute.style("text-align", "center"),
            ],
            [
              p(
                [
                  attribute.style("color", "#9ca3af"),
                  attribute.style("margin-bottom", "12px"),
                ],
                [
                  case model.running || model.timer >. 0.0 {
                    True -> text("TARGET: " <> float_to_2digit(model.target))
                    False -> text("CURRENT TIME")
                  },
                ],
              ),

              case model.hidden {
                True ->
                  p(
                    [
                      attribute.style("font-size", "64px"),
                      attribute.style("font-family", "monospace"),
                      attribute.style("color", "white"),
                    ],
                    [text("????")],
                  )

                False ->
                  p(
                    [
                      attribute.style("font-size", "64px"),
                      attribute.style("font-family", "monospace"),
                      attribute.style("color", "white"),
                    ],
                    [text(float_to_2digit(model.timer))],
                  )
              },
            ],
          ),

          div(
            [
              attribute.style("display", "flex"),
              attribute.style("gap", "12px"),
              attribute.style("margin-top", "32px"),
            ],
            [
              button(
                [
                  on_click(Start),
                  attribute.disabled(model.running || !model.ready),
                  attribute.style("flex", "1"),
                  attribute.style("padding", "14px"),
                  attribute.style("background", "#10b981"),
                  attribute.style("color", "white"),
                  attribute.style("border", "none"),
                  attribute.style("border-radius", "10px"),
                  attribute.style("font-weight", "bold"),
                ],
                [text("START")],
              ),

              button(
                [
                  on_click(Stop),
                  attribute.style("flex", "1"),
                  attribute.style("padding", "14px"),
                  attribute.style("background", "#ef4444"),
                  attribute.style("color", "white"),
                  attribute.style("border", "none"),
                  attribute.style("border-radius", "10px"),
                  attribute.style("font-weight", "bold"),
                ],
                [text("STOP")],
              ),

              button(
                [
                  on_click(Reset),
                  attribute.style("flex", "1"),
                  attribute.style("padding", "14px"),
                  attribute.style("background", "#6b7280"),
                  attribute.style("color", "white"),
                  attribute.style("border", "none"),
                  attribute.style("border-radius", "10px"),
                  attribute.style("font-weight", "bold"),
                ],
                [text("RESET")],
              ),
            ],
          ),

          div(
            [
              attribute.style("margin-top", "24px"),
              attribute.style("padding", "16px"),
              attribute.style("background", "#f9fafb"),
              attribute.style("border-radius", "12px"),
            ],
            [
              p([], [text("判定結果")]),
              p(
                [
                  attribute.style("font-size", "18px"),
                  attribute.style("font-weight", "bold"),
                ],
                [
                  case string.starts_with(model.result, "エラー:") {
                    True -> text("")
                    False -> text(model.result)
                  },
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}



fn float_to_2digit(value: Float) -> String {
  let total = float.round(value *. 100.0)

  let secs = total / 100
  let centis = total % 100

  two_digits(secs)
    <> "."
    <> two_digits(centis)
}

fn every_10ms() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { start_interval(fn() { dispatch(Tick) }, 10) })
}

fn hide_after_2sec() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { start_timeout(fn() { dispatch(HideTimer) }, 2000) })
}

fn parse_int_clamped(value: String, minimum: Int, maximum: Int) -> Int {
  let parsed =
    case int.parse(string.trim(value)) {
      Ok(v) -> v
      Error(_) -> minimum
    }

  case parsed < minimum {
    True -> minimum
    False ->
      case parsed > maximum {
        True -> maximum
        False -> parsed
      }
  }
}

fn two_digits(value: Int) -> String {
  case value < 10 {
    True -> "0" <> int.to_string(value)
    False -> int.to_string(value)
  }
}