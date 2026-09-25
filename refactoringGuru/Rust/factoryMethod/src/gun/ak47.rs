use super::Gun;

pub struct Ak47 {
    pub name: String,
    pub power: u32,
}

impl Gun for Ak47 {
    fn name(&self) -> &str {
        &self.name
    }

    fn power(&self) -> u32 {
        self.power
    }

}

impl Ak47 {
    pub fn new() -> Self {
        Self {
            name: "AK47".to_string(),
            power: 4,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_an_ak47_with_expected_values() {
        let ak47 = Ak47::new();

        assert_eq!(ak47.name, "AK47");
        assert_eq!(ak47.power, 4);
    }
}
