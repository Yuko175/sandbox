use super::Gun;

pub struct Musket {
    pub name: String,
    pub power: u32,
}

impl Gun for Musket {
    fn name(&self) -> &str {
        &self.name
    }

    fn power(&self) -> u32 {
        self.power
    }
}

impl Musket {
    pub fn new() -> Self {
        Self {
            name: "Musket".to_string(),
            power: 1,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_a_musket_with_expected_values() {
        let musket = Musket::new();

        assert_eq!(musket.name, "Musket");
        assert_eq!(musket.power, 1);
    }
}
