import KombiWelcome from './assets/kombi-275.png';
import { Auction } from './Auction';

export function Welcome() {
  return (
    <div className="w-screen h-screen flex flex-col-reverse items-center lg:flex-col lg:justify-between bg-orange-light text-white font-mono max-w-screen">
      <div className="flex flex-col lg:flex-row w-full h-full max-w-[1600px] max-h-[900px]">
        <div className="w-full lg:w-[55%] flex justify-center py-6 sm:py-8 lg:py-0">
            <img 
              src={KombiWelcome} 
              alt="Kombi" 
              className="w-full max-w-[300px] h-auto"
            />
        </div>

        <Auction onNextAuction={() => {}} onPreviousAuction={() => {}} auctionItemData={'teste'} />
      </div>
    </div>
  );
}
