package gun

type IGun interface {
	SetName(name GunName)
	SetPower(power int)
	GetName() GunName
	GetPower() int
}
