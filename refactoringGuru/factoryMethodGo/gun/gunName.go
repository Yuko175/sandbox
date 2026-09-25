package gun

import "fmt"

type GunName string

const (
	AK47   GunName = "ak47"
	MUSKET GunName = "musket"
)

func NewGunName(name string) (GunName, error) {
	gunName := GunName(name)
	if !gunName.isValid() {
		return "", fmt.Errorf("invalid gun name: %s", name)
	}
	return gunName, nil
}

func (gunName GunName) isValid() bool {
	switch gunName {
	case AK47, MUSKET:
		return true
	default:
		return false
	}
}
