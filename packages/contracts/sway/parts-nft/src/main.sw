contract;

use std::block::timestamp;
use std::string::String;
use std::storage::storage_string::*;

use sway_libs::{
    admin::{
        add_admin,
        is_admin,
        only_admin,
        revoke_admin,
    },
    ownership::{
        _owner,
        initialize_ownership,
        only_owner,
        transfer_ownership,
    },
};

use parts_nft_abi::{AccessoryType, AccessoryAddedEvent};

const ACCESSORY_CYCLE_LENGTH: u64 = 3;

configurable {
    INITIAL_OWNER: Identity = Identity::Address(Address::zero()),
}

storage {
    start_date: u64 = 0,
    accessory_types: StorageMap<AccessoryType, u64> = StorageMap {},
    accessory_metadata: StorageMap<(AccessoryType, u64), StorageString> = StorageMap {},
}

#[storage(read)]
fn acessory_of_day() -> AccessoryType {
    let start_date = storage.start_date.read();
    let target_date = (timestamp() / 86400);
    let days_since_start = target_date - (start_date / 86400);
    let cycle_position = days_since_start % ACCESSORY_CYCLE_LENGTH;

    match cycle_position {
        0 => AccessoryType::Item,
        1 => AccessoryType::Wheels,
        _ => AccessoryType::PaintJob,
    }
}

abi PartsNft {
    #[storage(read)]
    fn acessory_of_day() -> AccessoryType;

    #[storage(read, write)]
    fn add_accessory(accessory: AccessoryType, value: String);

    #[storage(read)]
    fn get_accessory(accessory: AccessoryType) -> Option<u64>;
}

impl PartsNft for Contract {
    #[storage(read)]
    fn acessory_of_day() -> AccessoryType {
        acessory_of_day()
    }

    #[storage(read, write)]
    fn add_accessory(accessory: AccessoryType, value: String) {
        let accessory_id = storage.accessory_types.get(accessory).try_read().unwrap_or(0);  
        let _ = storage.accessory_metadata.try_insert((accessory, accessory_id), StorageString {});
        storage
            .accessory_metadata
            .get((accessory, accessory_id))
            .write_slice(value);
        storage.accessory_types.insert(accessory, accessory_id + 1);

        log(AccessoryAddedEvent {
            accessory: accessory,
            accessory_id: accessory_id,
            value: value,
            sender: msg_sender().unwrap(),
        });
    }

    #[storage(read)]
    fn get_accessory(accessory: AccessoryType) -> Option<u64> {
        storage.accessory_types.get(accessory).try_read()
    }
}

abi Constructor {
    #[storage(read, write)]
    fn constructor(admin: Identity);
}

impl Constructor for Contract {
    #[storage(read, write)]
    fn constructor(admin: Identity) {
        initialize_ownership(INITIAL_OWNER);
        add_admin(admin);
        storage.start_date.write(timestamp());
    }
}