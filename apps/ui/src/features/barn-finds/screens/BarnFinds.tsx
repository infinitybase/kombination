import { Auction } from '@/components/Auction';
import { auctionsMock } from '@/utils/mocks';
import KombiWelcome from '@kombination/ui-components/assets/kombi-275.png'
import { useState } from 'react';

export function BarnFinds() {
  const [currentAuctionItem, setCurrentAuctionItem] = useState(auctionsMock[0]);

  return (
    <div className="w-full h-full flex flex-col-reverse items-center lg:flex-col bg-yellow-light text-white font-mono max-w-screen">
      <div className="flex flex-col xl:flex-row xl:justify-between w-full h-full max-w-max-width max-h-max-height">
        <div className="w-full xl:w-[55%] flex justify-center items-center py-6 sm:py-8 xl:py-0">
            <img 
              src={KombiWelcome} 
              alt="Kombi" 
              className="w-full max-w-[400px]"
            />
        </div>

        <Auction onNextAuction={() => {}} onPreviousAuction={() => {}} auctionItemData={currentAuctionItem} />
      </div>
    </div>
  );
}
