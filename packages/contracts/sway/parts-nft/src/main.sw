contract;

use std::block::timestamp;

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

use parts_nft_abi::{PartsNft, AccessoryType};

const ACCESSORY_CYCLE_LENGTH: u64 = 3;

configurable {
    INITIAL_OWNER: Identity = Identity::Address(Address::zero()),
}

storage {
    start_date: u64 = 0,
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

impl PartsNft for Contract {
    #[storage(read)]
    fn acessory_of_day() -> AccessoryType {
        acessory_of_day()
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