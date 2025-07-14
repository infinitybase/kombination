library;

use std::{
    bytes::Bytes,
    codec::{encode},
    block::{timestamp, height},
    hash::{keccak256},
    bytes_conversions::{u256::*, u64::*}
};

pub fn seed(token_id: u64) -> u64 {
    let sender = msg_sender().unwrap();
    let seed = keccak256({
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from(encode(u256::from(token_id))));
        bytes.append(Bytes::from(encode(u256::from(timestamp()))));
        bytes.append(Bytes::from(encode(u256::from(height()))));
        bytes.append(Bytes::from(encode(sender.bits())));
        bytes
    });
    let parts = asm(r1: u256::from(seed)) {
        r1: (u64, u64, u64, u64)
    };

    let combined = parts.0 
        ^ (parts.1 << 16 | parts.1 >> 48)
        ^ (parts.2 << 32 | parts.2 >> 32)
        ^ (parts.3 << 48 | parts.3 >> 16);

    combined
}