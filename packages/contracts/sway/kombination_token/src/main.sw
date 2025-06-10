contract;

use std::bytes::Bytes;
use std::hash::{Hash, Hasher, sha256};
use standards::{src20::SRC20, src5::{SRC5, State}, src7::{Metadata, SRC7}};
use sway_libs::{
    asset::{
        base::{
            _name,
            _symbol,
            _total_assets,
            _total_supply,
        },
        metadata::*,
    },
    ownership::{
        _owner,
        initialize_ownership,
        only_owner,
    },
    pausable::{
        _is_paused,
        _pause,
        _unpause,
        Pausable,
    },
};
use std::{storage::storage_string::*, string::String};

configurable {
    INITIAL_OWNER: Address = Address::zero(),
    NAME: str[11] = __to_str_array("Kombination"),
    SYMBOL: str[3] = __to_str_array("KMB"),
}

enum PartType {
    HeadLight: (),
    Bumper: (),
    Antenna: (),
    Mirror: (),
    Screens: (),
    SideStep: (),
}

enum AssetType {
    Kombi: (),
    Part: PartType,
}

struct PartMetadata {
    bg_image: String,
    image: String,
    uri: String,
}

const PART_PREFIX: b256 = 0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc;
type PartSubId = b256;

fn part_sub_id(part_id: u64) -> PartSubId {
    sha256((PART_PREFIX, part_id))
}

struct PartRegisteredEvent {
    part_id: u64,
    part_type: PartType,
    metadata: PartMetadata,
}

storage {
    asset {
        total_assets: u64 = 0,
        total_supply: StorageMap<AssetId, u64> = StorageMap {},
        name: StorageMap<AssetId, StorageString> = StorageMap {},
        symbol: StorageMap<AssetId, StorageString> = StorageMap {},
        metadata: StorageMetadata = StorageMetadata {},
    },
    parts {
        total_parts: u64 = 0,
        part_type: StorageMap<PartSubId, PartType> = StorageMap {},
        metadata: StorageMetadata = StorageMetadata {},
    },
}

abi KombinationToken {
    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata);

    #[storage(read)]
    fn get_part_type(part_id: u64) -> Option<PartType>;
}

impl KombinationToken for Contract {
    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata) {
        // TODO: Only owner can register parts
        let part_id = storage::parts.total_parts.read();
        let sub_id = part_sub_id(part_id);

        log(sub_id);

        require(
            storage::parts.part_type.get(sub_id).try_read().is_none(), 
            "Part already registered"
        );

        storage::parts.part_type.insert(sub_id, part);

        let asset_id = AssetId::new(ContractId::zero(), sub_id);
        _set_metadata(
            storage::asset.metadata, 
            asset_id, 
            String::from_ascii_str("bg_image"), 
            Metadata::String(metadata.bg_image)
        );
        _set_metadata(
            storage::asset.metadata, 
            asset_id, 
            String::from_ascii_str("image"), 
            Metadata::String(metadata.image)
        );
        _set_metadata(
            storage::asset.metadata, 
            asset_id, 
            String::from_ascii_str("uri"), 
            Metadata::String(metadata.uri)
        );

        storage::parts.total_parts.write(part_id + 1);

        log(PartRegisteredEvent {
            part_id,
            part_type: part,
            metadata,
        });
    }

    #[storage(read)]
    fn get_part_type(part_id: u64) -> Option<PartType> {
        storage::parts.part_type.get(part_sub_id(part_id)).try_read()
    }
}

impl SRC20 for Contract {
    #[storage(read)]
    fn total_assets() -> u64 {
        _total_assets(storage::asset.total_assets)
    }
    
    #[storage(read)]
    fn total_supply(asset: AssetId) -> Option<u64> {
        _total_supply(storage::asset.total_supply, asset)
    }
    
    #[storage(read)]
    fn name(asset: AssetId) -> Option<String> {
        match storage::asset.total_supply.get(asset).try_read() {
            Some(_) => Some(String::from_ascii_str(from_str_array(NAME))),
            None => None,
        }
    }

    #[storage(read)]
    fn symbol(asset: AssetId) -> Option<String> {
        match storage::asset.total_supply.get(asset).try_read() {
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
        storage::asset.metadata.get(asset, key)
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
    fn constructor(owner: Identity);
}

impl Constructor for Contract {
    #[storage(read, write)]
    fn constructor(owner: Identity) {
        initialize_ownership(owner);
    }
}