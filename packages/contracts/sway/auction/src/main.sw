contract;

mod interfaces;
mod events;
mod auction;

use sway_libs::pausable::{_is_paused, _pause, _unpause, Pausable, require_not_paused};
use sway_libs::ownership::{initialize_ownership, only_owner, transfer_ownership};
use sway_libs::reentrancy::*;
use std::{asset::transfer, block::timestamp, hash::sha256, storage::storage_vec::*};

use auction::{Auction, AuctionId};
use interfaces::{AuctionError, KombinationAuction, Ownership, StartAuction};
use events::{AuctionEndedEvent, AuctionStartedEvent, BidPlacedEvent, BidWithdrawnEvent};

// Configuration for the auction contract.
configurable {
    /// Minimum bid increase percentage
    MIN_BID_INCREASE: u64 = 5,
    /// Time buffer to allow for last-minute bids
    TIME_BUFFER: u64 = 60,
}

/// Main contract storage.
storage {
    // Auctions map
    auctions: StorageMap<AuctionId, Auction> = StorageMap {},
    // Pending bidders map
    pending_bidders: StorageMap<AuctionId, StorageMap<Identity, u64>> = StorageMap {},
}

fn _get_auction_id(auction: StartAuction) -> AuctionId {
    sha256((auction.asset_id, auction.end_time))
}
#[storage(read)]
fn _get_auction(auction_id: AuctionId) -> Auction {
    let auction = storage.auctions.get(auction_id).try_read();
    require(auction.is_some(), AuctionError::AuctionNotFound(auction_id));
    auction.unwrap()
}

impl KombinationAuction for Contract {
    /// Places a bid on an auction.
    #[storage(write, read), payable]
    fn place_bid(auction_id: AuctionId, amount: u64) {
        reentrancy_guard();
        require_not_paused();
        let mut auction = _get_auction(auction_id);
        let is_available_to_bid = auction.end_time > timestamp();
        require(
            is_available_to_bid,
            AuctionError::AuctionNotActive(auction_id),
        );
        let min_next_bid = auction.highest_bid + (auction.highest_bid * MIN_BID_INCREASE / 100);
        let bid_with_min_next_bid = auction.highest_bid + min_next_bid;
        require(
            amount >= bid_with_min_next_bid,
            AuctionError::BidTooLow(amount),
        );
        let sender = msg_sender().unwrap();

        match auction.highest_bidder {
            Some(previous_highest_bidder) => {
                storage
                    .pending_bidders
                    .get(auction_id)
                    .insert(previous_highest_bidder, auction.highest_bid);
            }
            // is first bid
            None => {
                auction.start_time = Some(timestamp());
                auction.active = true;
            }
        }

        let is_last_minute = auction.end_time - timestamp() <= TIME_BUFFER;
        if is_last_minute {
            auction.end_time += TIME_BUFFER;
        }
        let pending_bidders = storage.pending_bidders.get(auction_id);
        pending_bidders.remove(sender);

        // update auction highest bid and bidder
        auction.highest_bidder = Some(sender);
        auction.highest_bid = amount;
        storage.auctions.insert(auction_id, auction);

        log(BidPlacedEvent {
            auction_id,
            bidder: sender,
            amount,
        });
    }

    ///  Starts a new auction.
    #[storage(write, read)]
    fn start_auction(payload: StartAuction) -> AuctionId {
        only_owner();
        require_not_paused();
        let auction_id = _get_auction_id(payload);
        // let already_exists = auctions.get(auction_id).read_slice().unwrap();
        // require(!already_exists, AuctionError::AuctionAlreadyExists(payload.asset_id));
        require(
            payload
                .end_time > timestamp(),
            AuctionError::EndTimeInPast(payload.end_time),
        );
        require(
            payload
                .initial_bid > 0,
            AuctionError::InitialBidTooLow(payload.initial_bid),
        );
        let auction = Auction::new(
            payload
                .asset_id,
            payload
                .end_time,
            payload
                .initial_bid,
            None,
        );
        storage.auctions.insert(auction_id, auction);
        storage.pending_bidders.insert(auction_id, StorageMap {});
        log(AuctionStartedEvent {
            auction_id,
            asset_id: payload.asset_id,
            end_time: payload.end_time,
            initial_bid: payload.initial_bid,
        });
        auction_id
    }

    /// Ends an auction and transfers the asset to the highest bidder.
    #[storage(write, read)]
    fn end_auction(auction_id: AuctionId) {
        only_owner();
        require_not_paused();
        let mut auction = _get_auction(auction_id);
        require(auction.active, AuctionError::AuctionNotActive(auction_id));

        transfer(auction.highest_bidder.unwrap(), auction.asset_id, 1);

        auction.active = false;
        storage.auctions.insert(auction_id, auction);
    }

    /// Gets the highest bid for an auction.
    #[storage(read)]
    fn get_highest_bid(auction_id: AuctionId) -> (Option<Identity>, u64) {
        let auction = _get_auction(auction_id);
        (auction.highest_bidder, auction.highest_bid)
    }

    /// Places a bid on an auction.
    #[storage(read)]
    fn is_active(auction_id: AuctionId) -> bool {
        let auction = _get_auction(auction_id);
        auction.active
    }

    /// Withdraws a bid from an auction.
    #[storage(read, write)]
    fn withdraw_bid(auction_id: AuctionId) {
        require_not_paused();
        let auction = _get_auction(auction_id);

        let sender = msg_sender().unwrap();

        require(auction.highest_bidder != Some(sender), AuctionError::SenderIsHighestBidder(sender));

        let amount = storage.pending_bidders.get(auction_id).get(sender).try_read();
        require(amount.is_some(), AuctionError::BidNotFound(sender));

        let amount = amount.unwrap();

        transfer(sender, auction.asset_id, amount);
        storage.pending_bidders.get(auction_id).remove(sender); // Returns bool, but ignored
        log(BidWithdrawnEvent {
            auction_id,
            bidder: sender,
            amount,
        });
    }
}

impl Ownership for Contract {
    #[storage(read, write)]
    fn initialize(owner: Identity) {
        initialize_ownership(owner);
    }
    #[storage(write)]
    fn transfer_ownership(new_owner: Identity) {
        transfer_ownership(new_owner);
    }
}

impl Pausable for Contract {
    #[storage(write)]
    fn pause() {
        only_owner();
        _pause();
    }
    #[storage(write)]
    fn unpause() {
        only_owner();
        _unpause();
    }
    #[storage(read)]
    fn is_paused() -> bool {
        _is_paused()
    }
}
