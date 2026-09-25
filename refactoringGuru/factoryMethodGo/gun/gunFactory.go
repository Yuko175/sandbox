package gun

import "fmt"

func GetGun(gunType GunName) (IGun, error) {
	
	if gunType == AK47 {
		return newAk47(), nil
	}
	if gunType == MUSKET {
		return newMusket(), nil
	}
	return nil, fmt.Errorf("Wrong gun type passed")
}
