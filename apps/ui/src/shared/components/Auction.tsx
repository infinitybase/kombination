import { Badge } from "@kombination/ui-components/shadcn/badge.js"; 
import { Button } from "@kombination/ui-components/shadcn/button.js"; 

interface IAuctionProps {
  auctionItemData: string;
  onNextAuction: () => void;
  onPreviousAuction: () => void;
}

export function Auction({
  auctionItemData,
  onNextAuction,
  onPreviousAuction
}: IAuctionProps) {
  return (
    <div className="bg-gray-primary px-6 py-4 lg:m-6 lg:w-[40%] flex flex-col gap-6 pixel-frame">
      <div className="w-full flex justify-between items-center">
        <Button variant="ghost" className="text-warning" onClick={onPreviousAuction}>«</Button>
        <span className="text-body text-warning">data de hoje :D</span>
        <Button variant="ghost" className="text-warning" onClick={onNextAuction}>»</Button>
      </div>
      <div className="w-full flex flex-col gap-3">
        <h1 className="text-title font-bold">Kombi 1979</h1>
        <p className="text-body text-warning">
          Fresh from the barn, this '78 T2 Kombi is ready for a second life. Dressed in faded orange, it Proudly features a custom sunroof, making it a true revival masterpiece.
        </p>
        <div className="flex gap-2 sm:gap-3 md:gap-4">
          {["Type 1", "1.5L", "150.000km"].map(info => (
            <Badge variant="warning">{info}</Badge>
          ))}
        </div>
      </div>

      <div className="flex justify-between w-full">
        <div className="flex flex-col gap-2">
          <span className="text-body text-gray-400">Bid Price</span>
          <span className="text-subtitle font-bold text-warning">$200</span>
        </div>
        <div className="flex flex-col items-end bg-gray-700 p-2 sm:p-3 rounded">
          <span className="text-label sm:text-xs text-gray-400">Auction Ends in</span>
          <span className="text-red-500 text-label sm:text-xs font-semibold">13h42m05s</span>
        </div>
      </div>

      <hr className='bg-gray-400 w-full' />

      <div className="w-full flex flex-col items-center gap-4">
        <p className="text-body text-gray-400">Bid $210 or more</p>
        <Button type="button" variant="success" className="p-6">
          CONNECT WALLET
        </Button>
      </div>

      <hr className='bg-gray-400 w-full' />

      <div className="w-full flex flex-col gap-2 pt-4 text-warning">
        <div className="flex justify-between text-body">
          <span>@luisburigo</span>
          <span>$200</span>
        </div>
        <div className="flex justify-between text-body">
          <span>0x01...C3df</span>
          <span>$180</span>
        </div>
        <div className="flex justify-between text-body">
          <span>@fabioseva</span>
          <span>$150</span>
        </div>
      </div>
    </div>
  )
}