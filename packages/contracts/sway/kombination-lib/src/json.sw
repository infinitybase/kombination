library;

use std::{
    string::String,
    bytes::Bytes,
};
use ::base64::{base64_encode};

const ESCAPE_CHARS: u8 = 0x5c;

fn remove_escape_chars(input: Bytes) -> String {
    let mut output = Bytes::new();
    let mut i = 0;
    while i < input.len() {
        if input.get(i).unwrap() != ESCAPE_CHARS {
            output.push(input.get(i).unwrap());
        }
        i += 1;
    }
    String::from_ascii(output)
}

fn escape_json_string(input: String) -> String {
    let mut output = Bytes::new();
    output.push(0x22); // "
    output.append(input.as_bytes());
    output.push(0x22); // "
    String::from_ascii(output)
}

fn concat_str(values: Vec<String>) -> String {
    let mut output = Bytes::new();
    let mut i = 0;
    while i < values.len() {
        output.append(values.get(i).unwrap().as_bytes());
        i += 1;
    }
    String::from_ascii(output)
}

fn create_json_property(key: str, value: str) -> String {
    let mut strings: Vec<String> = Vec::new();
    strings.push(escape_json_string(String::from_ascii_str(key)));
    strings.push(String::from_ascii_str(":"));
    strings.push(escape_json_string(String::from_ascii_str(value)));
    concat_str(strings)
}

fn create_json_property_array(key: str, values: Vec<String>) -> String {
    let mut output = Bytes::new();
    output.push(0x5b); // [
    let mut i = 0;
    while i < values.len() {
        output.append(values.get(i).unwrap().as_bytes());
        if i < values.len() - 1 {
            output.push(0x2c); // ,
        }
        i += 1;
    }
    output.push(0x5d); // ]
    let mut strings: Vec<String> = Vec::new();
    strings.push(escape_json_string(String::from_ascii_str(key)));
    strings.push(String::from_ascii_str(":"));
    strings.push(String::from_ascii(output));
    concat_str(strings)
}

fn create_json_object(properties: Vec<String>) -> String {
    let mut output = Bytes::new();
    output.push(0x7b); // {
    let mut i = 0;
    while i < properties.len() {
        output.append(properties.get(i).unwrap().as_bytes());
        if i < properties.len() - 1 {
            output.push(0x2c); // ,
        }
        i += 1;
    }
    output.push(0x7d); // }
    String::from_ascii(output)
}

fn create_json_attribute(trait_type: str, value: str) -> String {
    let mut strings: Vec<String> = Vec::new();
    strings.push(create_json_property("trait_type", trait_type));
    strings.push(create_json_property("value", value));
    create_json_object(strings)
}

pub struct JSONBuilder {
    properties: Vec<String>,
}

impl JSONBuilder {
    pub fn new() -> Self {
        Self { properties: Vec::new() }
    }

    pub fn add_property(self, key: str, value: str) -> Self {
        let mut properties = self.properties;
        properties.push(create_json_property(key, value));
        Self { properties }
    }

    pub fn add_property_array(self, key: str, values: Vec<(str, str)>) -> Self {
        let mut properties = self.properties;
        let mut array_properties: Vec<String> = Vec::new();
        let mut i = 0;
        while i < values.len() {
            let (key, value) = values.get(i).unwrap();
            array_properties.push(create_json_attribute(key, value));
            i += 1;
        }

        properties.push(create_json_property_array(key, array_properties));
        Self { properties }
    }

    pub fn build(self) -> String {
        let mut properties = self.properties;
        create_json_object(properties)
    }

    pub fn as_base64(self) -> String {
        let mut vec: Vec<String> = Vec::new();
        vec.push(String::from_ascii_str("data:application/json;base64,"));
        vec.push(base64_encode(self.build().as_bytes()));
        concat_str(vec)
    }
}