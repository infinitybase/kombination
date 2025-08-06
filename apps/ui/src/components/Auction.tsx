import { BidPlacedDialog } from "@/features/barn-finds/components/BidPlacedDialog";
import type { AuctionData } from "@/features/barn-finds/types";
import { useCountdown } from "@/hooks/useCountdown";
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
  const [bidAmount, setBidAmount] = useState<number>(); // TEMPORARY
  const [bidPlaced, setBidPlaced] = useState(false); 
  const [bidPlacedDialogOpen, setBidPlacedDialogOpen] = useState(false);
  const bids = auctionItemData.bids.sort((a,b) => a.amount > b.amount ? -1 : 1);
  const isWalletConnected = true // TEMPORARY
  const minBidPermitted = auctionItemData.currentBidAmount + 10 // TEMPORARY
  const countdown = useCountdown(auctionItemData.date)

  function handlePlaceBid() {
    // TODO

    setBidPlacedDialogOpen(true)
    setBidPlaced(true)
  }

  return (
    <div className="xl:w-[40%] xl:mt-10 xl:me-8 xl:mb-10 xl:pixel-frame">
      <div className="w-full h-full bg-gray-primary xl:pixel-clip-custom p-5 flex flex-col gap-4 z-1">
        <div className="w-full flex justify-between items-center">
          <Button variant="ghost" className="text-warning hover:text-white" onClick={onPreviousAuction}>«</Button>
          <span className="text-body text-white">{formatDate(auctionItemData.date)}</span>
          <Button variant="ghost" className="text-warning hover:text-white" onClick={onNextAuction}>»</Button>
        </div>
        <div className="w-full flex flex-col gap-3">
          <h1 className="text-subtitle font-bold">{auctionItemData.name}</h1>
          <p className="text-label text-warning">
            {auctionItemData.description}
          </p>
          <div className="flex gap-2 sm:gap-3 md:gap-4">
            {auctionItemData.infos.map(info => (
              <Badge variant="warning">{info}</Badge>
            ))}
          </div>
        </div>

        <hr className='border-1 border-gray-tertiary w-full' />

        <div className="flex justify-between">
          {
            !auctionItemData.isClosed && (
              <>
                <div className="flex flex-col justify-between w-full">
                  <div className="flex flex-col gap-2">
                    <span className="text-label text-gray-light">Bid Price</span>
                    <span className="text-subsection font-bold text-warning">${auctionItemData.currentBidAmount}</span>
                  </div>
                  <div className="flex flex-col gap-2">
                    <span className="text-label text-gray-light">Auction Ends in</span>
                    <span className="text-danger text-body font-semibold">{countdown}</span>
                  </div>
                </div>
                
                <div className="w-full xl:w-[70%] flex flex-col items-stretch justify-between gap-2">
                  <p className="text-label align-end text-gray-light">Bid ${minBidPermitted} or more</p>
                  {
                    isWalletConnected && !auctionItemData.isClosed ? (
                      <>
                        <Input 
                          id="bid_amount"
                          className="text-success"
                          align="center"
                          type="number" 
                          value={bidAmount} 
                          min={minBidPermitted}
                          disabled={bidPlaced}
                          onChange={(e) => setBidAmount(e.target.valueAsNumber)} 
                          />
                        <Button 
                          type="button" 
                          variant={bidPlaced ? "default" : "success"} 
                          className="p-4" 
                          size="sm" 
                          disabled={bidPlaced || !bidAmount}
                          onClick={handlePlaceBid}
                          >
                            {bidPlaced ? "Bid Placed!" : "Place Bid"}
                        </Button>
                      </>
                    ) : (
                      <Button type="button" variant="success" className="p-4" size="sm" >
                        CONNECT WALLET
                      </Button>
                    )
                  }
                </div>
              </>
            )
          }

          {
            auctionItemData.isClosed && (
              <>
                <div className="flex flex-col gap-2">
                  <span className="text-label text-gray-light">Winning Bid</span>
                  <span className="text-subsection font-bold text-warning">${auctionItemData.currentBidAmount}</span>
                </div>
                <div className="flex flex-col gap-2">
                  <span className="text-label text-gray-light">Held by</span>
                  <span className="text-subsection font-bold text-warning flex gap-2 items-center">
                    {auctionItemData.winner} 
                    <Trophy size={18} />
                  </span>
                </div>
              </>
            )
          }
        </div>
          
        <hr className='border-1 border-gray-tertiary w-full' />

        <p className="text-label text-gray-light">All Bids</p>
        <div className="w-full flex flex-col gap-2 pt-2 overflow-auto scrollbar-custom pr-2">
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

      <BidPlacedDialog isOpen={bidPlacedDialogOpen} setIsOpen={setBidPlacedDialogOpen} />
    </div>
  )
}