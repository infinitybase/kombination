contract;

use std::bytes::Bytes;
use std::context::msg_amount;
use std::call_frames::msg_asset_id;
use std::hash::{Hash, Hasher, sha256};
use std::convert::Into;
use standards::{src20::SRC20, src5::{SRC5, State}, src7::{Metadata, SRC7}};
use sway_libs::{
    asset::{
        supply::{_burn, _mint},
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

const PART_PREFIX: b256 = 0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc;
const KOMBI_PREFIX: b256 = 0x390643a7ea067800e503b0510f4a6e3f1cc9b114b09dd9d140553f76a19a0620;

configurable {
    INITIAL_OWNER: Address = Address::zero(),
    NAME: str[11] = __to_str_array("Kombination"),
    SYMBOL: str[3] = __to_str_array("KMB"),
}

/// TYPES
type PartSubId = b256;
type KombiTypeSubId = b256;

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

/// IMPLEMENTATIONS
impl Into<u8> for PartType {
    fn into(self) -> u8 {
        match self {
            PartType::HeadLight => 0,
            PartType::Bumper => 1,
            PartType::Antenna => 2,
            PartType::Mirror => 3,
            PartType::Screens => 4,
            PartType::SideStep => 5,
        }
    }
}

impl Hash for PartType {
    fn hash(self, ref mut state: Hasher) {
        let value: u8 = self.into();
        value.hash(state);
    }
}

impl Hash for AssetType {
    fn hash(self, ref mut state: Hasher) {
        match self {
            AssetType::Kombi => {
                "Kombi".hash(state);
                0u8.hash(state);
            },
            AssetType::Part(part_type) => {
                "Part".hash(state);
                part_type.hash(state);
            },
        }
    }
}

/// UTILS
fn part_sub_id(part_id: u64) -> PartSubId {
    sha256((PART_PREFIX, part_id))
}

/// EVENTS
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

struct KombiMintedEvent {
    kombi_id: KombiTypeSubId,
    asset_id: AssetId,
    recipient: Identity,
}

struct PartAttachedToKombiEvent {
    part_id: PartSubId,
    kombi_id: KombiTypeSubId,
    part_type: PartType,
    owner: Identity,
}

struct PartDetachedFromKombiEvent {
    part_id: PartSubId,
    kombi_id: KombiTypeSubId,
    part_type: PartType,
    owner: Identity,
}

storage {
    asset {
        total_assets: u64 = 0,
        total_supply: StorageMap<AssetId, u64> = StorageMap {},
        asset_sub_id: StorageMap<AssetId, SubId> = StorageMap {},
        name: StorageMap<AssetId, StorageString> = StorageMap {},
        symbol: StorageMap<AssetId, StorageString> = StorageMap {},
        asset_type: StorageMap<AssetId, AssetType> = StorageMap {},
        total_assets_type: StorageMap<AssetType, u64> = StorageMap {},
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
        // Track which parts are attached to each kombi
        kombi_parts: StorageMap<KombiTypeSubId, StorageMap<PartType, PartSubId>> = StorageMap {},
        // Track which kombi a part belongs to (if any)
        part_attached_to_kombi: StorageMap<PartSubId, AssetId> = StorageMap {},
    }
}

abi KombinationToken {
    #[storage(read, write)]
    fn mint_part(part_id: PartSubId, recipient: Identity);

    #[storage(read, write)]
    fn mint_kombi(kombi_id: KombiTypeSubId, recipient: Identity);

    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata);

    #[storage(read, write)]
    fn register_kombi_type(metadata: KombiTypeMetadata);

    #[storage(read, write), payable]
    fn attach_part(kombi_asset_id: AssetId);

    #[storage(read, write), payable]
    fn detach_part(part_asset_id: AssetId);

    #[storage(read)]
    fn get_part_type(part_id: PartSubId) -> Option<PartType>;

    #[storage(read)]
    fn get_asset_type(asset_id: AssetId) -> Option<AssetType>;

    #[storage(read)]
    fn get_total_assets_type(asset_type: AssetType) -> u64;

    #[storage(read)]
    fn get_kombi_parts(kombi_asset_id: AssetId, part_type: PartType) -> Option<AssetId>;

    #[storage(read)]
    fn is_part_attached_to_kombi(part_asset_id: AssetId) -> Option<AssetId>;
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

        _mint(
            storage::asset.total_assets,
            storage::asset.total_supply,
            recipient,
            part_id,
            1,
        );

        let total_assets_type = storage::asset.total_assets_type.get(AssetType::Part(part_type.unwrap())).try_read().unwrap_or(0);
        storage::asset.total_assets_type.insert(AssetType::Part(part_type.unwrap()), total_assets_type + 1);
        storage::asset.asset_sub_id.insert(asset_id, part_id);

        storage::asset.asset_type.insert(
            asset_id, 
            AssetType::Part(part_type.unwrap())
        );

        log(PartMintedEvent {
            part_id,
            asset_id,
            recipient,
        });
    }

    #[storage(read, write)]
    fn mint_kombi(kombi_id: KombiTypeSubId, recipient: Identity) {
        // TODO: Only admin can mint kombi
        let total_assets = storage::asset.total_assets_type.get(AssetType::Kombi).try_read().unwrap_or(0);
        let sub_id = sha256((kombi_id, total_assets));
        let asset_id = AssetId::new(ContractId::zero(), sub_id);

        require(
            storage::asset.total_supply.get(asset_id).try_read().is_none(),
            "Kombi already minted"
        );

        let asset_id = _mint(
            storage::asset.total_assets,
            storage::asset.total_supply,
            recipient,
            sub_id,
            1,
        );

        storage::asset.asset_type.insert(asset_id, AssetType::Kombi);
        storage::asset.asset_sub_id.insert(asset_id, kombi_id);

        let total_assets_type = storage::asset.total_assets_type.get(AssetType::Kombi).try_read().unwrap_or(0);
        storage::asset.total_assets_type.insert(AssetType::Kombi, total_assets_type + 1);

        log(KombiMintedEvent {
            kombi_id,
            asset_id,
            recipient,
        });
    }

    #[storage(read, write)]
    fn register_part(part: PartType, metadata: PartMetadata) {
        // TODO: Only admin can register parts
        let part_id = storage::parts.total_parts.get(part).try_read().unwrap_or(0);
        let sub_id = sha256((PART_PREFIX, part, part_id));

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
            storage::parts.metadata, 
            asset_id, 
            String::from_ascii_str("bg_image"), 
            Metadata::String(metadata.bg_image)
        );
        _set_metadata(
            storage::parts.metadata, 
            asset_id, 
            String::from_ascii_str("image"), 
            Metadata::String(metadata.image)
        );
        _set_metadata(
            storage::parts.metadata, 
            asset_id, 
            String::from_ascii_str("uri"), 
            Metadata::String(metadata.uri)
        );
        _set_metadata(
            storage::parts.metadata, 
            asset_id, 
            String::from_ascii_str("kombi_type_id"), 
            Metadata::B256(metadata.kombi_type_id)
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

    #[storage(read, write), payable]
    fn attach_part(kombi_asset_id: AssetId) {
        // Verify that the kombi exists and is valid
        let kombi_asset_type = storage::asset.asset_type.get(kombi_asset_id).try_read();
        require(kombi_asset_type.is_some(), "Kombi does not exist");
        
        match kombi_asset_type.unwrap() {
            AssetType::Kombi => {},
            _ => {
                require(false, "Provided asset is not a kombi");
            }
        }

        // Get the kombi type from the asset_sub_id
        let kombi_type_id = match storage::asset.asset_sub_id.get(kombi_asset_id).try_read() {
            Some(sub_id) => sub_id,
            None => {
                require(false, "Kombi sub ID not found");
                return;
            }
        };
        
        require(msg_amount() == 1, "Must send exactly 1 part token");

        let received_asset = msg_asset_id();

        // Verify that the received asset is a part
        let part_asset_type = match storage::asset.asset_type.get(received_asset).try_read() {
            Some(asset_type) => asset_type,
            None => {
                require(false, "Received asset is not registered");
                return;
            }
        };

        let part_type = match part_asset_type {
            AssetType::Part(part_type) => part_type,
            AssetType::Kombi => {
                require(false, "Cannot attach a kombi to another kombi");
                return;
            }
        };

        // Get the part's sub_id to check compatibility
        let part_sub_id = match storage::asset.asset_sub_id.get(received_asset).try_read() {
            Some(sub_id) => sub_id,
            None => {
                require(false, "Part sub ID not found");
                return;
            }
        };

        // Check if this part is compatible with the kombi type
        let part_kombi_type = match storage::parts.part_kombi_type.get(part_sub_id).try_read() {
            Some(part_kombi_type) => {
                require(part_kombi_type == kombi_type_id, "Part is not compatible with this kombi type");
                part_kombi_type
            },
            None => {
                require(false, "Part kombi type not found");
                return;
            }
        };

        // Check if the kombi already has a part of this type
        require(
            storage::kombi.kombi_parts.get(kombi_type_id).get(part_type).try_read().is_none(), 
            "Kombi already has a part of this type"
        );

        // Check if the part is already attached to another kombi
        require(
            storage::kombi.part_attached_to_kombi.get(part_sub_id).try_read().is_none(), 
            "Part is already attached to another kombi"
        );

        // Burn the part token by removing it from total supply
        _burn(storage::asset.total_supply, part_sub_id, 1);

        // Attach the part to the kombi
        storage::kombi.kombi_parts.get(kombi_type_id).insert(part_type, part_sub_id);
        storage::kombi.part_attached_to_kombi.insert(part_sub_id, kombi_asset_id);

        // Log the event
        log(PartAttachedToKombiEvent {
            part_id: part_sub_id,
            kombi_id: kombi_type_id,
            part_type,
            owner: msg_sender().unwrap(),
        });
    }

    #[storage(read, write), payable]
    fn detach_part(part_asset_id: AssetId) {
        require(msg_amount() == 1, "Must send exactly 1 kombi token");

        let part_asset_type = storage::asset.asset_type.get(part_asset_id).try_read();
        require(part_asset_type.is_some(), "Part does not exist");

        match part_asset_type.unwrap() {
            AssetType::Part(_) => {},
            AssetType::Kombi => {
                require(false, "Cannot detach a kombi from a kombi");
                return;
            }
        }

        let part_sub_id = match storage::asset.asset_sub_id.get(part_asset_id).try_read() {
            Some(sub_id) => sub_id,
            None => {
                require(false, "Part sub ID not found");
                return;
            }
        };

        let part_type = match storage::parts.part_type.get(part_sub_id).try_read() {
            Some(part_type) => part_type,
            None => {
                require(false, "Part type not found");
                return;
            }
        };

        let kombi_sub_id = match storage::kombi.part_attached_to_kombi.get(part_sub_id).try_read() {
            Some(kombi_asset_id) => {
                require(kombi_asset_id == msg_asset_id(), "Part is not attached to this kombi");
                storage::asset.asset_sub_id.get(kombi_asset_id).try_read().unwrap()
            },
            None => {
                require(false, "Part is not attached to a kombi");
                return;
            }
        };

        // Detach the part from the kombi
        storage::kombi.kombi_parts.get(kombi_sub_id).remove(part_type);
        storage::kombi.part_attached_to_kombi.remove(part_sub_id);

        // Mint the part back to the user
        _mint(
            storage::asset.total_assets,
            storage::asset.total_supply,
            msg_sender().unwrap(),
            part_sub_id,
            1,
        );

        // Log the event
        log(PartDetachedFromKombiEvent {
            part_id: part_sub_id,
            kombi_id: kombi_sub_id,
            part_type,
            owner: msg_sender().unwrap(),
        });
    }

    #[storage(read)]
    fn get_part_type(part_id: PartSubId) -> Option<PartType> {
        storage::parts.part_type.get(part_id).try_read()
    }

    #[storage(read)]
    fn get_asset_type(asset_id: AssetId) -> Option<AssetType> {
        storage::asset.asset_type.get(asset_id).try_read()
    }

    #[storage(read)]
    fn get_total_assets_type(asset_type: AssetType) -> u64 {
        storage::asset.total_assets_type.get(asset_type).try_read().unwrap_or(0)
    }

    #[storage(read)]
    fn get_kombi_parts(kombi_asset_id: AssetId, part_type: PartType) -> Option<AssetId> {
        match storage::asset.asset_sub_id.get(kombi_asset_id).try_read() {
            Some(kombi_sub_id) => {
                match storage::kombi.kombi_parts.get(kombi_sub_id).get(part_type).try_read() {
                    Some(part_sub_id) => {
                        Some(AssetId::new(ContractId::this(), part_sub_id))
                    }
                    None => None,
                }
            }
            None => None,
        }
    }

    #[storage(read)]
    fn is_part_attached_to_kombi(part_asset_id: AssetId) -> Option<AssetId> {
        match storage::asset.asset_sub_id.get(part_asset_id).try_read() {
            Some(part_sub_id) => storage::kombi.part_attached_to_kombi.get(part_sub_id).try_read(),
            None => None,
        }
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
        let sub_id = match storage::asset.asset_sub_id.get(asset).try_read() {
            Some(sub_id) => sub_id,
            None => return None,
        };

        let asset_type = match storage::asset.asset_type.get(asset).try_read() {
            Some(asset_type) => asset_type,
            None => return None,
        };

        let asset_id = AssetId::new(ContractId::zero(), sub_id);

        match asset_type {
            AssetType::Part(_) => {
                _metadata(storage::parts.metadata, asset_id, key)
            }
            AssetType::Kombi => {
                _metadata(storage::kombi.metadata, asset_id, key)
            }
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
    fn constructor(owner: Identity);
}

impl Constructor for Contract {
    #[storage(read, write)]
    fn constructor(owner: Identity) {
        initialize_ownership(owner);
    }
}