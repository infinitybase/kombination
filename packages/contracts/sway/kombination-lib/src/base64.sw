library;

use std::{
    string::String,
    bytes::Bytes,
};

pub fn base64_encode(input: Bytes) -> String {
    let mut input = input;
    let c = input.len() % 3;
    let pad_count = if c > 0 { 3 - c } else { 0 };
    let mut i = 0;
    while i < pad_count {
        input.push(0);
        i += 1;
    }
    let mut output = Bytes::new();
    let mut i = 0;
    while i + 2 < input.len() {
        let n: u64 = (input.get(i).unwrap().as_u64() << 16) + (input.get(i + 1).unwrap().as_u64() << 8) + input.get(i + 2).unwrap().as_u64();
        let n0 = (n >> 18) & 63;
        let n1 = (n >> 12) & 63;
        let n2 = (n >> 6) & 63;
        let n3 = n & 63;
        output.push(BASE64_DICT[n0]);
        output.push(BASE64_DICT[n1]);
        output.push(BASE64_DICT[n2]);
        output.push(BASE64_DICT[n3]);
        i += 3;
    }
    let mut i = 0;
    while i < pad_count {
        output.pop();
        i += 1;
    }
    let mut i = 0;
    while i < pad_count {
        output.push(0x3d); // =
        i += 1;
    }
    String::from_ascii(output)
}

pub fn base64_decode(input: String) -> Bytes {
    let mut input = filter_base64_chars(input.as_bytes());
    let mut pad_count = 0;
    if let Some(0x3d) = input.get(input.len() - 1) {
        input.set(input.len() - 1, 0x41); // A
        pad_count += 1;
    }
    if let Some(0x3d) = input.get(input.len() - 2) {
        input.set(input.len() - 2, 0x41); // A
        pad_count += 1;
    }
    let mut output = Bytes::new();
    let mut i = 0;
    while i < input.len() {
        let n = (dict_index(input.get(i).unwrap()).unwrap() << 18) + (dict_index(input.get(i + 1).unwrap()).unwrap() << 12) + (dict_index(input.get(i + 2).unwrap()).unwrap() << 6) + dict_index(input.get(i + 3).unwrap()).unwrap();
        output.push(((n >> 16) & 255).try_as_u8().unwrap());
        output.push(((n >> 8) & 255).try_as_u8().unwrap());
        output.push((n & 255).try_as_u8().unwrap());
        i += 4;
    }
    let mut i = 0;
    while i < pad_count {
        output.pop();
        i += 1;
    }
    output
}

fn filter_base64_chars(input: Bytes) -> Bytes {
    let mut output = Bytes::new();
    let mut i = 0;
    while i < input.len() {
        let c = input.get(i).unwrap();
        if is_base64_char(c) {
            output.push(c);
        }
        i += 1;
    }
    output
}

fn is_base64_char(c: u8) -> bool {
    if c == 0x3d { // =
        return true;
    }
    dict_index(c).is_some()
}

fn dict_index(c: u8) -> Option<u64> {
    let mut i = 0;
    while i < 64 {
        if BASE64_DICT[i] == c {
            return Some(i);
        }
        i += 1;
    }
    None
}

const BASE64_DICT: [u8; 64] = [
    0x41,
    0x42,
    0x43,
    0x44,
    0x45,
    0x46,
    0x47,
    0x48,
    0x49,
    0x4a,
    0x4b,
    0x4c,
    0x4d,
    0x4e,
    0x4f,
    0x50,
    0x51,
    0x52,
    0x53,
    0x54,
    0x55,
    0x56,
    0x57,
    0x58,
    0x59,
    0x5a,
    0x61,
    0x62,
    0x63,
    0x64,
    0x65,
    0x66,
    0x67,
    0x68,
    0x69,
    0x6a,
    0x6b,
    0x6c,
    0x6d,
    0x6e,
    0x6f,
    0x70,
    0x71,
    0x72,
    0x73,
    0x74,
    0x75,
    0x76,
    0x77,
    0x78,
    0x79,
    0x7a,
    0x30,
    0x31,
    0x32,
    0x33,
    0x34,
    0x35,
    0x36,
    0x37,
    0x38,
    0x39,
    0x2d, // 0x2b
    0x5f, // 0x2f
];