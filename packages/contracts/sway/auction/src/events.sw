library;

type AuctionId = b256;

pub struct BidPlacedEvent {
    pub auction_id: AuctionId,
    pub bidder: Identity,
    pub amount: u64,
}

pub struct AuctionStartedEvent {
    pub auction_id: AuctionId,
    pub asset_id: AssetId,
    pub end_time: u64,
    pub initial_bid: u64,
}

pub struct AuctionEndedEvent {
    pub auction_id: AuctionId,
    pub winner: Identity,
    pub winning_bid: u64,
}

pub struct BidWithdrawnEvent {
    pub auction_id: AuctionId,
    pub bidder: Identity,
    pub amount: u64,
}
