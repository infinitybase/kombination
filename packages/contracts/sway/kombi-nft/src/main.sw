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
use kombination_lib::{seed::seed, string::{b256_to_ascii_bytes, concat}};

configurable {
    INITIAL_OWNER: Identity = Identity::Address(Address::zero()),
    NAME: str[11] = __to_str_array("Kombination"),
    SYMBOL: str[3] = __to_str_array("KMB"),
    PARTS_ADDRESS: ContractId = ContractId::zero(),
}

storage {
    total_assets: u64 = 0,
    metadata: StorageMap<AssetId, KombiMetadata> = StorageMap {},
    total_supply: StorageMap<AssetId, u64> = StorageMap {},
    component_types: StorageMap<ComponentType, u64> = StorageMap {},
    component_metadata: StorageMap<(ComponentType, u64), StorageString> = StorageMap {},
    base_metadata_uri: StorageString = StorageString {},
}

#[storage(read)]
fn random_metadata(seed: u64) -> KombiMetadata {
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
        bumper: seed % bumper,
        antenna: seed % antenna,
        mirror: seed % mirror,
        screens: seed % screens,
        side_step: seed % side_step,
        kombi_type: seed % kombi_type,
        mileage: seed % 500000, // 0-500km
        birth_date: timestamp(),
        engine_info: seed % engine_info,
        custom_text: seed % custom_text,
    }
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
        let metadata = random_metadata(value);

        storage.metadata.insert(asset_id, metadata);

        let asset_id = _mint(storage.total_assets, storage.total_supply, to, sub_id, 1);

        let sender = msg_sender().unwrap();
        let base_uri = storage.base_metadata_uri.read_slice().unwrap();
        let asset_bytes = b256_to_ascii_bytes(asset_id.bits());

        SetMetadataEvent::new(
            asset_id,
            Some(Metadata::String(generate_uri(base_uri, asset_bytes, "/metadata.json"))),
            String::from_ascii_str("uri"),
            sender,
        ).log();

        SetMetadataEvent::new(
            asset_id,
            Some(Metadata::String(generate_uri(base_uri, asset_bytes, "/image.png"))),
            String::from_ascii_str("image"),
            sender,
        ).log();

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
        let total_supply = storage.total_supply.get(asset).try_read();
        if total_supply.is_none() {
            return None;
        }

        let base_uri = storage.base_metadata_uri.read_slice().unwrap();
        let asset_bytes = b256_to_ascii_bytes(asset.bits());

        match key.as_str() {
            "uri" => Some(Metadata::String(generate_uri(base_uri, asset_bytes, "/metadata.json"))),
            "image" => Some(Metadata::String(generate_uri(base_uri, asset_bytes, "/image.png"))),
            _ => None,
        }
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
