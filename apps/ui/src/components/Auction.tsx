import type { AuctionData } from "@/features/barn-finds/types";
import { formatDate } from "@/utils/formatDate";
import { Badge } from "@kombination/ui-components/shadcn/badge.js"; 
import { Button } from "@kombination/ui-components/shadcn/button.js"; 
import { Input } from "@kombination/ui-components/shadcn/input.js";
import { Trophy } from "lucide-react";
import { useState } from "react";

interface IAuctionProps {
  auctionItemData: AuctionData;
  onNextAuction: () => void;
  onPreviousAuction: () => void;
}

export function Auction({
  auctionItemData,
  onNextAuction,
  onPreviousAuction
}: IAuctionProps) {
  const [bidPlaced, setBidPlaced] = useState<number>();
  const bids = auctionItemData.bids.sort((a,b) => a.amount > b.amount ? -1 : 1);
  const isWalletConnected = true 
  const minBidPermitted = auctionItemData.currentBidAmount + 10

  return (
    <div className="xl:w-[40%] xl:mt-10 xl:me-8 xl:mb-10 xl:pixel-frame">
      <div className="w-full h-full bg-gray-primary xl:pixel-clip-custom p-6 flex flex-col gap-6 z-1">
        <div className="w-full flex justify-between items-center">
          <Button variant="ghost" className="text-warning" onClick={onPreviousAuction}>«</Button>
          <span className="text-body text-white">{formatDate(auctionItemData.date)}</span>
          <Button variant="ghost" className="text-warning" onClick={onNextAuction}>»</Button>
        </div>
        <div className="w-full flex flex-col gap-3">
          <h1 className="text-subsection font-bold">{auctionItemData.name}</h1>
          <p className="text-label text-warning">
            {auctionItemData.description}
          </p>
          <div className="flex gap-2 sm:gap-3 md:gap-4">
            {auctionItemData.infos.map(info => (
              <Badge variant="warning">{info}</Badge>
            ))}
          </div>
        </div>

        <hr className='border-2 border-gray-tertiary w-full' />

        <div className="flex justify-between">
          <div className="flex flex-col justify-between w-full">
            <div className="flex flex-col gap-2">
              <span className="text-label text-gray-light">Bid Price</span>
              <span className="text-subsection font-bold text-warning">${auctionItemData.currentBidAmount}</span>
            </div>
            <div className="flex flex-col gap-2">
              <span className="text-label text-gray-light">Auction Ends in</span>
              <span className="text-danger text-label font-semibold">13h42m05s</span>
            </div>
          </div>

          
          <div className="w-full xl:w-[70%] flex flex-col items-stretch justify-between gap-3">
            <p className="text-label align-end text-gray-light">Bid ${minBidPermitted} or more</p>
            {
              isWalletConnected ? (
                <>
                  <Input 
                    id="bid_amount"
                    textType="success"
                    align="center"
                    type="number" 
                    value={bidPlaced} 
                    min={minBidPermitted}
                    onChange={(e) => setBidPlaced(e.target.valueAsNumber)} 
                    />
                  <Button type="button" variant="success" className="p-4" size="sm" >
                    Place Bid
                  </Button>
                </>
              ) : (
                <Button type="button" variant="success" className="p-4" size="sm" >
                  CONNECT WALLET
                </Button>
              )
            }
          </div>
        </div>
          
        <hr className='border-2 border-gray-tertiary w-full' />

        <p className="text-label text-gray-light">All Bids</p>
        <div className="w-full flex flex-col gap-2 pt-2">
          {bids.map((bid, index) => {
            return (
              <div key={bid.name} className={`flex justify-between text-label text-beige-light ${index === 0 && 'text-warning'}`}>
                <span className="flex gap-2">{bid.name}{index === 0 && <Trophy size={12} />}</span>
                <span>{bid.amount}</span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}