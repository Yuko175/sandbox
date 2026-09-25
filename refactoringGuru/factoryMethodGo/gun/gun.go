package gun

type Gun struct {
	name  GunName
	power int
}

func (g *Gun) SetName(name GunName) {
	g.name = name
}

func (g *Gun) GetName() GunName {
	return g.name
}

func (g *Gun) SetPower(power int) {
	g.power = power
}

func (g *Gun) GetPower() int {
	return g.power
}
