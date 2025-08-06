export type AuctionData = {
    id_auction: number
    name: string,
    description: string,
    infos: string[],
    category: string,
    date: Date,
    currentBidAmount: number,
    isClosed: boolean,
    winner: string | null,
    bids: BidsData[]
}

export type BidsData = {
  name: string,
  amount: number
}