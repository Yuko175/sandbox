import land_magic/game/main as game
import land_magic/view/main as view
import lustre

/// 概要: アプリケーションを起動します。
/// 引数: この関数は引数を受け取りません。
/// 戻り値: 起動処理だけを行うので、`Nil` を返します。
pub fn main() -> Nil {
  let app = lustre.simple(game.init, game.update, view.render)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
