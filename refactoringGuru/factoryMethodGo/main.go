package main

import (
	"factoryMethod/gun"
	"fmt"
)

func main() {
	ak47, _ := gun.GetGun(gun.AK47)
	musket, _ := gun.GetGun(gun.MUSKET)
	printDetails(ak47)
	printDetails(musket)
}

func printDetails(g gun.IGun) {
	fmt.Printf("Gun: %s", g.GetName())
	fmt.Println()
	fmt.Printf("Power: %d", g.GetPower())
	fmt.Println()
}
