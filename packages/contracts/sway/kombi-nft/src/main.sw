contract;

use std::{
    block::{
        timestamp,
    },
    bytes::Bytes,
    call_frames::msg_asset_id,
    context::msg_amount,
    convert::Into,
    hash::{
        sha256,
    },
};
use standards::{src20::SRC20, src5::{SRC5, State}, src7::{Metadata, SetMetadataEvent, SRC7}};
use sway_libs::{
    admin::{
        add_admin,
        is_admin,
        only_admin,
        revoke_admin,
    },
    asset::{
        base::{
            _name,
            _symbol,
            _total_assets,
            _total_supply,
        },
        metadata::*,
        supply::{
            _burn,
            _mint,
        },
    },
    ownership::{
        _owner,
        initialize_ownership,
        only_owner,
        transfer_ownership,
    },
    pausable::{
        _is_paused,
        _pause,
        _unpause,
        Pausable,
        require_not_paused,
    },
};
use std::{storage::storage_string::*, string::String};
use kombi_nft_abi::{ComponentAddedEvent, ComponentType, KombiMetadata, KombiMintedEvent};
use kombination_lib::{seed::seed, string::{b256_to_ascii_bytes, concat}, json::JSONBuilder};

configurable {
    INITIAL_OWNER: Identity = Identity::Address(Address::zero()),
    NAME: str[11] = __to_str_array("Kombination"),
    SYMBOL: str[3] = __to_str_array("KMB"),
    PARTS_ADDRESS: ContractId = ContractId::zero(),
}

storage {
    total_assets: u64 = 0,
    asset_metadata: StorageMetadata = StorageMetadata {},
    metadata: StorageMap<AssetId, KombiMetadata> = StorageMap {},
    total_supply: StorageMap<AssetId, u64> = StorageMap {},
    component_types: StorageMap<ComponentType, u64> = StorageMap {},
    component_metadata: StorageMap<(ComponentType, u64), StorageString> = StorageMap {},
    base_metadata_uri: StorageString = StorageString {},
}

pub fn u64_to_ascii_string(num: u64) -> String {
    let mut num = num;
    let mut bytes = Bytes::new();
    let result = match num {
        0 => {
            bytes.push(48); // ascii for 0
            bytes
        }
        _ => {
            while num > 0 {
                let mut be_bytes = (num % 10).to_be_bytes();
                let digit = be_bytes.pop().unwrap() + 48;
                bytes.push(digit);
                num /= 10;
            }
            // there's no for loop???
            let len = bytes.len();
            let mut i = 0;
            while i < len / 2 {
                bytes.swap(i, len - i - 1);
                i += 1;
            }
            bytes
        }
    };
    String::from_ascii(result)
}

#[storage(read)]
fn random_metadata(seed: u64, kombi_id: u64) -> KombiMetadata {
    let head_light = storage.component_types.get(ComponentType::HeadLight).try_read().unwrap_or(0);
    let bumper = storage.component_types.get(ComponentType::Bumper).try_read().unwrap_or(0);
    let antenna = storage.component_types.get(ComponentType::Antenna).try_read().unwrap_or(0);
    let mirror = storage.component_types.get(ComponentType::Mirror).try_read().unwrap_or(0);
    let screens = storage.component_types.get(ComponentType::Screens).try_read().unwrap_or(0);
    let side_step = storage.component_types.get(ComponentType::SideStep).try_read().unwrap_or(0);
    let kombi_type = storage.component_types.get(ComponentType::KombiType).try_read().unwrap_or(0);
    let engine_info = storage.component_types.get(ComponentType::EngineInfo).try_read().unwrap_or(0);
    let custom_text = storage.component_types.get(ComponentType::CustomText).try_read().unwrap_or(0);

    KombiMetadata {
        head_light: seed % head_light,
        bumper: (seed >> 8) % bumper,
        antenna: (seed >> 16) % antenna,
        mirror: (seed >> 24) % mirror,
        screens: (seed >> 32) % screens,
        side_step: (seed >> 40) % side_step,
        kombi_type: (seed >> 48) % kombi_type,
        engine_info: (seed >> 56) % engine_info,
        custom_text: (seed >> 64) % custom_text,
        mileage: seed % 500000, // 0-500km
        birth_date: timestamp(),
        kombi_id: kombi_id,
    }
}

#[storage(read, write)]
fn generate_json_metadata(asset_id: AssetId, image_uri: String) -> Option<String> {
    let metadata = storage.metadata.get(asset_id).try_read();
    if metadata.is_none() {
        return None;
    }

    let metadata = metadata.unwrap();
    let json = JSONBuilder::new()
        .add_property("name", concat(String::from_ascii_str("Kombi #"), u64_to_ascii_string(metadata.kombi_id)).as_str())
        .add_property("image", image_uri.as_str());

    let head_light = storage.component_metadata.get((ComponentType::HeadLight, metadata.head_light)).read_slice().unwrap();
    let bumper = storage.component_metadata.get((ComponentType::Bumper, metadata.bumper)).read_slice().unwrap();
    let antenna = storage.component_metadata.get((ComponentType::Antenna, metadata.antenna)).read_slice().unwrap();
    let mirror = storage.component_metadata.get((ComponentType::Mirror, metadata.mirror)).read_slice().unwrap();
    let screens = storage.component_metadata.get((ComponentType::Screens, metadata.screens)).read_slice().unwrap();
    let side_step = storage.component_metadata.get((ComponentType::SideStep, metadata.side_step)).read_slice().unwrap();
    let kombi_type = storage.component_metadata.get((ComponentType::KombiType, metadata.kombi_type)).read_slice().unwrap();
    let engine_info = storage.component_metadata.get((ComponentType::EngineInfo, metadata.engine_info)).read_slice().unwrap();
    let custom_text = storage.component_metadata.get((ComponentType::CustomText, metadata.custom_text)).read_slice().unwrap();
    let mileage = u64_to_ascii_string(metadata.mileage);
    let birth_date = u64_to_ascii_string(metadata.birth_date);

    let mut attributes: Vec<(str, str)> = Vec::new();
    attributes.push(("Head Light", head_light.as_str()));
    attributes.push(("Bumper", bumper.as_str()));
    attributes.push(("Antenna", antenna.as_str()));
    attributes.push(("Mirror", mirror.as_str()));
    attributes.push(("Screens", screens.as_str()));
    attributes.push(("Side Step", side_step.as_str()));
    attributes.push(("Kombi Type", kombi_type.as_str()));
    attributes.push(("Mileage", mileage.as_str()));
    attributes.push(("Birth Date", birth_date.as_str()));
    attributes.push(("Engine Info", engine_info.as_str()));
    attributes.push(("Custom Text", custom_text.as_str()));

    let json = json.add_property_array("attributes", attributes);

    Some(json.as_base64())
}

fn generate_uri(base_uri: String, asset_bytes: Bytes, file_name: str) -> String {
    let base_uri = concat(base_uri, "0x".into());
    let base_uri = concat(base_uri, String::from_ascii(asset_bytes));
    concat(base_uri, String::from_ascii_str(file_name))
}

abi KombiNFT {
    #[storage(read, write)]
    fn add_component(component: ComponentType, value: String);

    #[storage(read)]
    fn get_component(component: ComponentType) -> Option<u64>;

    #[storage(read, write)]
    fn mint(to: Identity);
}

impl KombiNFT for Contract {
    #[storage(read, write)]
    fn add_component(component: ComponentType, value: String) {
        only_admin();

        let component_id = storage.component_types.get(component).try_read().unwrap_or(0);
        let _ = storage.component_metadata.try_insert((component, component_id), StorageString {});
        storage
            .component_metadata
            .get((component, component_id))
            .write_slice(value);
        storage.component_types.insert(component, component_id + 1);

        log(ComponentAddedEvent {
            component: component,
            component_id: component_id,
            value: value,
            sender: msg_sender().unwrap(),
        });
    }

    #[storage(read)]
    fn get_component(component: ComponentType) -> Option<u64> {
        storage.component_types.get(component).try_read()
    }

    #[storage(read, write)]
    fn mint(to: Identity) {
        require_not_paused();
        only_admin();

        let total_assets = storage.total_assets.read();
        let sub_id = total_assets.as_u256().as_b256();
        let asset_id = AssetId::new(ContractId::this(), sub_id);

        require(
            storage
                .total_supply
                .get(asset_id)
                .try_read()
                .is_none(),
            "Asset already minted",
        );

        let value = seed(total_assets);
        let metadata = random_metadata(value, total_assets);

        storage.metadata.insert(asset_id, metadata);

        let asset_id = _mint(storage.total_assets, storage.total_supply, to, sub_id, 1);

        let sender = msg_sender().unwrap();
        let base_uri = storage.base_metadata_uri.read_slice().unwrap();
        let asset_bytes = b256_to_ascii_bytes(asset_id.bits());
        
        let image_uri = generate_uri(base_uri, asset_bytes, "/image.png");
        let metadata_uri = generate_json_metadata(asset_id, image_uri).unwrap();

        _set_metadata(storage.asset_metadata, asset_id, String::from_ascii_str("uri"), Metadata::String(metadata_uri));
        _set_metadata(storage.asset_metadata, asset_id, String::from_ascii_str("image"), Metadata::String(image_uri));

        log(KombiMintedEvent {
            asset_id: asset_id,
            metadata: metadata,
            to: to,
        });
    }
}

impl SRC20 for Contract {
    #[storage(read)]
    fn total_assets() -> u64 {
        _total_assets(storage.total_assets)
    }

    #[storage(read)]
    fn total_supply(asset: AssetId) -> Option<u64> {
        _total_supply(storage.total_supply, asset)
    }

    #[storage(read)]
    fn name(asset: AssetId) -> Option<String> {
        match storage.total_supply.get(asset).try_read() {
            Some(_) => Some(String::from_ascii_str(from_str_array(NAME))),
            None => None,
        }
    }

    #[storage(read)]
    fn symbol(asset: AssetId) -> Option<String> {
        match storage.total_supply.get(asset).try_read() {
            Some(_) => Some(String::from_ascii_str(from_str_array(SYMBOL))),
            None => None,
        }
    }

    #[storage(read)]
    fn decimals(_asset: AssetId) -> Option<u8> {
        Some(0u8)
    }
}

impl SRC7 for Contract {
    #[storage(read)]
    fn metadata(asset: AssetId, key: String) -> Option<Metadata> {
        _metadata(storage.asset_metadata, asset, key)
    }
}

impl SRC5 for Contract {
    #[storage(read)]
    fn owner() -> State {
        _owner()
    }
}

impl Pausable for Contract {
    #[storage(write)]
    fn pause() {
        only_owner();
        _pause();
    }

    #[storage(read)]
    fn is_paused() -> bool {
        _is_paused()
    }

    #[storage(write)]
    fn unpause() {
        only_owner();
        _unpause();
    }
}

abi Constructor {
    #[storage(read, write)]
    fn constructor(admin: Identity, base_metadata_uri: String);
}

impl Constructor for Contract {
    #[storage(read, write)]
    fn constructor(admin: Identity, base_metadata_uri: String) {
        initialize_ownership(INITIAL_OWNER);
        add_admin(admin);
        storage.base_metadata_uri.write_slice(base_metadata_uri);
    }
}

abi Ownership {
    #[storage(read, write)]
    fn add_admin(admin: Identity);

    #[storage(read)]
    fn is_admin(admin: Identity) -> bool;

    #[storage(read, write)]
    fn revoke_admin(admin: Identity);

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);
}

impl Ownership for Contract {
    #[storage(read, write)]
    fn add_admin(admin: Identity) {
        only_owner();
        add_admin(admin);
    }

    #[storage(read)]
    fn is_admin(admin: Identity) -> bool {
        is_admin(admin)
    }

    #[storage(read, write)]
    fn revoke_admin(admin: Identity) {
        only_owner();
        revoke_admin(admin);
    }

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity) {
        only_owner();
        transfer_ownership(new_owner);
    }
}
