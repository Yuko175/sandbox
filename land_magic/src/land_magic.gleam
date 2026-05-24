import land_magic/game
import land_magic/view
import lustre

pub fn main() -> Nil {
  let app = lustre.simple(game.init, game.update, view.render)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
