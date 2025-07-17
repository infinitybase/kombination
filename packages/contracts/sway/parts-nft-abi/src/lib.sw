library;

use std::hash::{Hash, Hasher};
use std::string::String;
use std::convert::Into;

pub enum AccessoryType {
    Item: (),
    Wheels: (),
    PaintJob: ()
}

impl Into<String> for AccessoryType {
    fn into(self) -> String {
        match self {
            AccessoryType::Item => String::from_ascii_str("item"),
            AccessoryType::Wheels => String::from_ascii_str("wheels"),
            AccessoryType::PaintJob => String::from_ascii_str("paint_job"),
        }
    }
}

impl Into<u8> for AccessoryType {
    fn into(self) -> u8 {
        match self {
            AccessoryType::Item => 0,
            AccessoryType::Wheels => 1,
            AccessoryType::PaintJob => 2,
        }
    }
}

impl Hash for AccessoryType {
    fn hash(self, ref mut state: Hasher) {
        let string: String = self.into();
        state.write(string.into());
    }
}

pub struct AccessoryMetadata {
    pub accessory_type: AccessoryType,
    pub item_type: u64,
    pub kombi_type: u64,
    pub custom_text: u64,
    pub birth_date: u64,
    pub rarity: u64,
}

abi PartsNft {
    #[storage(read)]
    fn acessory_of_day() -> AccessoryType;
}