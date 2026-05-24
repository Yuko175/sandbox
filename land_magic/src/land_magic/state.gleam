import land_magic/domain.{other_turn}
import land_magic/types.{type Model, type Player, type Turn, PlayerOne, PlayerTwo, Model}

pub fn current_player(model: Model) -> Player {
  player_by_turn(model, model.turn)
}

pub fn opponent_player(model: Model) -> Player {
  player_by_turn(model, other_turn(model.turn))
}

pub fn player_by_turn(model: Model, turn: Turn) -> Player {
  case turn {
    PlayerOne -> model.player_one
    PlayerTwo -> model.player_two
  }
}

pub fn set_current_player(model: Model, player: Player) -> Model {
  set_player(model, model.turn, player)
}

pub fn set_opponent_player(model: Model, player: Player) -> Model {
  set_player(model, other_turn(model.turn), player)
}

pub fn set_player(model: Model, turn: Turn, player: Player) -> Model {
  case turn {
    PlayerOne -> Model(..model, player_one: player)
    PlayerTwo -> Model(..model, player_two: player)
  }
}
