library;

use std::{convert::Into, hash::{Hash, Hasher}, string::String};

abi KombiNFT {
    #[storage(read, write)]
    fn add_component(component: ComponentType, value: String);

    #[storage(read, write)]
    fn mint(to: Identity);
}

pub struct KombiMetadata {
    pub head_light: u64,
    pub bumper: u64,
    pub antenna: u64,
    pub mirror: u64,
    pub screens: u64,
    pub side_step: u64,
    pub kombi_type: u64,
    pub mileage: u64,
    pub birth_date: u64,
    pub engine_info: u64,
    pub custom_text: u64,
}

pub struct ComponentAddedEvent {
    pub component: ComponentType,
    pub component_id: u64,
    pub value: String,
    pub sender: Identity,
}

pub struct KombiMintedEvent {
    pub asset_id: AssetId,
    pub metadata: KombiMetadata,
    pub to: Identity,
}

pub enum ComponentType {
    HeadLight: (),
    Bumper: (),
    Antenna: (),
    Mirror: (),
    Screens: (),
    SideStep: (),
    KombiType: (),
    EngineInfo: (),
    CustomText: (),
}

impl Into<String> for ComponentType {
    fn into(self) -> String {
        match self {
            ComponentType::HeadLight => String::from_ascii_str("head_light"),
            ComponentType::Bumper => String::from_ascii_str("bumper"),
            ComponentType::Antenna => String::from_ascii_str("antenna"),
            ComponentType::Mirror => String::from_ascii_str("mirror"),
            ComponentType::Screens => String::from_ascii_str("screens"),
            ComponentType::SideStep => String::from_ascii_str("side_step"),
            ComponentType::KombiType => String::from_ascii_str("kombi_type"),
            ComponentType::EngineInfo => String::from_ascii_str("engine_info"),
            ComponentType::CustomText => String::from_ascii_str("custom_text"),
        }
    }
}

impl Hash for ComponentType {
    fn hash(self, ref mut state: Hasher) {
        let string: String = self.into();
        state.write(string.into());
    }
}
