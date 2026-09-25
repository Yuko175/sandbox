mod gun;

use gun::{Gun, GunFactory, GunType};

fn print_details(gun: &dyn Gun) {
    println!("Gun: {}", gun.name());
    println!("Power: {}", gun.power());
}

fn main() {
    let gun_factory = GunFactory;
    let ak47 = gun_factory.create(GunType::Ak47);
    let musket = gun_factory.create(GunType::Musket);

    print_details(ak47.as_ref());
    print_details(musket.as_ref());
}
