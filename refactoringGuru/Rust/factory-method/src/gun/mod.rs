pub mod ak47;
pub mod musket;

use ak47::Ak47;
use musket::Musket;

pub trait Gun {
    fn name(&self) -> &str;
    fn power(&self) -> u32;
}

pub enum GunType {
    Ak47,
    Musket,
}

pub struct GunFactory;

impl GunFactory {
    pub fn create(&self, gun_type: GunType) -> Box<dyn Gun> {
        match gun_type {
            GunType::Ak47 => Box::new(Ak47::new()),
            GunType::Musket => Box::new(Musket::new()),
        }
    }
}
