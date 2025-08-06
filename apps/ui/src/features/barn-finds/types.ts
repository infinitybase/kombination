export type AuctionData = {
    id_auction: number
    name: string,
    description: string,
    infos: string[],
    category: string,
    date: Date,
    currentBidAmount: number
    bids: BidsData[]
}

export type BidsData = {
  name: string,
  amount: number
}