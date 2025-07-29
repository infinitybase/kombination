library;

pub type AuctionId = b256;

pub struct Auction {
    // Asset being auctioned
    pub asset_id: AssetId,
    // time when the auction ends
    pub end_time: u64,
    // time when the auction starts
    pub start_time: Option<u64>,
    // Initial bid amount
    pub initial_bid: u64,
    // Status of the auction
    pub active: bool,
    // highest bidder and bid amount
    pub highest_bidder: Option<Identity>,
    pub highest_bid: u64,
}

impl Auction {
    pub fn new(
        asset_id: AssetId,
        end_time: u64,
        initial_bid: u64,
        start_time: Option<u64>,
    ) -> Self {
        Auction {
            asset_id,
            end_time,
            initial_bid,
            active: true,
            highest_bidder: None,
            highest_bid: 0,
            start_time,
        }
    }
}
