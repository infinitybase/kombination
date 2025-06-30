contract;

use std::bytes::Bytes;
use std::hash::{Hash, Hasher, sha256};
use standards::{src20::SRC20, src5::{SRC5, State}, src7::{Metadata, SRC7}};
use sway_libs::{
    asset::{
        supply::_mint,
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

impl Hash for PartType {
    fn hash(self, ref mut state: Hasher) {
        let value = match self {
            PartType::HeadLight => 0,
            PartType::Bumper => 1,
            PartType::Antenna => 2,
            PartType::Mirror => 3,
            PartType::Screens => 4,
            PartType::SideStep => 5,
        };
        value.hash(state);
    }
}

enum AssetType {
    Kombi: (),
    Part: PartType,
}

struct PartMetadata {
    kombi_type_id: KombiTypeSubId,
    bg_image: String,
    image: String,
    uri: String,
}

struct KombiTypeMetadata {
    name: String,
    description: String,
    bg_image: String,
    image: String,
    uri: String,
}

const PART_PREFIX: b256 = 0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc;
const KOMBI_PREFIX: b256 = 0x390643a7ea067800e503b0510f4a6e3f1cc9b114b09dd9d140553f76a19a0620;

type PartSubId = b256;
type KombiTypeSubId = b256;

fn part_sub_id(part_id: u64) -> PartSubId {
    sha256((PART_PREFIX, part_id))
}

struct PartRegisteredEvent {
    part_id: u64,
    sub_id: PartSubId,
    part_type: PartType,
    metadata: PartMetadata,
}

struct PartMintedEvent {
    part_id: PartSubId,
    asset_id: AssetId,
    recipient: Identity,
}

struct KombiTypeRegisteredEvent {
    kombi_id: u64,
    sub_id: KombiTypeSubId,
    metadata: KombiTypeMetadata,
}

storage {
    asset {
        total_assets: u64 = 0,
        total_supply: StorageMap<AssetId, u64> = StorageMap {},
        name: StorageMap<AssetId, StorageString> = StorageMap {},
        symbol: StorageMap<AssetId, StorageString> = StorageMap {},
        metadata: StorageMetadata = StorageMetadata {},
        asset_type: StorageMap<AssetId, AssetType> = StorageMap {},
    },
    parts {
        metadata: StorageMetadata = StorageMetadata {},
        total_parts: StorageMap<PartType, u64> = StorageMap {},
        part_type: StorageMap<PartSubId, PartType> = StorageMap {},
        part_kombi_type: StorageMap<PartSubId, KombiTypeSubId> = StorageMap {},
    },
    kombi {
        total_types: u64 = 0,
        kombi_type: StorageMap<KombiTypeSubId, bool> = StorageMap {},
        metadata: StorageMetadata = StorageMetadata {},
    }
}

abi KombinationToken {
    #[storage(read, write)]
    fn mint_part(part_id: PartSubId, recipient: Identity);

    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata);

    #[storage(read, write)]
    fn register_kombi_type(metadata: KombiTypeMetadata);

    #[storage(read)]
    fn get_part_type(part_id: PartSubId) -> Option<PartType>;
}

impl KombinationToken for Contract {
    #[storage(read, write)]
    fn mint_part(part_id: PartSubId, recipient: Identity) {
        // TODO: Only admin can mint parts
        let asset_id = AssetId::new(ContractId::this(), part_id);
        require(
            storage::asset.total_supply.get(asset_id).try_read().is_none(), 
            "Part already minted"
        );

        let part_type = storage::parts.part_type.get(part_id).try_read();
        require(
            part_type.is_some(),
            "Part not registered"
        );

        storage::asset.asset_type.insert(
            asset_id, 
            AssetType::Part(part_type.unwrap())
        );

        _mint(
            storage::asset.total_assets,
            storage::asset.total_supply,
            recipient,
            part_id,
            1,
        );

        log(PartMintedEvent {
            part_id,
            asset_id,
            recipient,
        });
    }

    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata) {
        // TODO: Only admin can register parts
        let part_id = storage::parts.total_parts.get(part).try_read().unwrap_or(0);
        let sub_id = part_sub_id(part_id);

        require(
            storage::parts.part_type.get(sub_id).try_read().is_none(), 
            "Part already registered"
        );

        require(
            storage::kombi.kombi_type.get(metadata.kombi_type_id).try_read().is_some(),
            "Kombi type not registered"
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

        storage::parts.part_kombi_type.insert(sub_id, metadata.kombi_type_id);
        storage::parts.total_parts.insert(part, part_id + 1);

        log(PartRegisteredEvent {
            part_id,
            sub_id,
            part_type: part,
            metadata,
        });
    }

    #[storage(read, write)]
    fn register_kombi_type(metadata: KombiTypeMetadata) {
        // TODO: Only admin can register kombi types
        let total_types = storage::kombi.total_types.read();
        let kombi_type_id = sha256((KOMBI_PREFIX, total_types));

        require(
            storage::kombi.kombi_type.get(kombi_type_id).try_read().is_none(),
            "Kombi type already registered"
        );

        let asset_id = AssetId::new(ContractId::zero(), kombi_type_id);

        _set_metadata(
            storage::kombi.metadata, 
            asset_id, 
            String::from_ascii_str("bg_image"), 
            Metadata::String(metadata.bg_image)
        );

        _set_metadata(
            storage::kombi.metadata, 
            asset_id, 
            String::from_ascii_str("image"), 
            Metadata::String(metadata.image)
        );

        _set_metadata(
            storage::kombi.metadata, 
            asset_id, 
            String::from_ascii_str("uri"), 
            Metadata::String(metadata.uri)
        );

        _set_metadata(
            storage::kombi.metadata, 
            asset_id, 
            String::from_ascii_str("name"), 
            Metadata::String(metadata.name)
        );

        _set_metadata(
            storage::kombi.metadata, 
            asset_id, 
            String::from_ascii_str("description"), 
            Metadata::String(metadata.description)
        );
        
        storage::kombi.total_types.write(total_types + 1);
        storage::kombi.kombi_type.insert(kombi_type_id, true);

        log(KombiTypeRegisteredEvent {
            kombi_id: total_types,
            sub_id: kombi_type_id,
            metadata,
        });
    }

    #[storage(read)]
    fn get_part_type(part_id: PartSubId) -> Option<PartType> {
        storage::parts.part_type.get(part_id).try_read()
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