package gun

type musket struct {
	Gun
}

func newMusket() IGun {
	return &musket{
		Gun: Gun{
			name:  MUSKET,
			power: 1,
		},
	}
}
