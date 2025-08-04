import KombiWelcome from './assets/kombi-275.png';

export function Welcome() {
  return (
    <div className="w-full flex flex-col items-center bg-primary text-white font-mono max-w-screen">
      {/* Main Content - Responsive for all screen sizes */}
      <div className="w-screen bg-transparent md:bg-[#FFC092]">
        <div className="flex flex-col md:flex-row md:max-w-[1600px] md:mx-auto md:py-12">
          {/* Image Section */}
          <div className="w-full md:w-1/2 flex justify-center py-6 sm:py-8 md:py-0 bg-[#FFC092]">
              <img 
                src={KombiWelcome} 
                alt="Kombi" 
                className="w-full max-w-[300px] h-auto"
              />
          </div>
          
          {/* Content Section */}
          <div className="w-full md:w-1/2 p-4 sm:p-6 md:p-8 lg:p-10 flex flex-col gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <h1 className="text-base sm:text-lg md:text-xl lg:text-2xl font-bold">Kombi 1979</h1>
            <p className="text-[10px] sm:text-xs md:text-sm lg:text-base">
              Fresh from the barn, this '78 T2 Kombi is ready for a second life. Dressed in faded orange, it Proudly features a custom sunroof, making it a true revival masterpiece.
            </p>
            <div className="flex gap-2 sm:gap-3 md:gap-4">
              <span className="bg-gray-700 px-2 sm:px-3 md:px-4 py-1 md:py-2 text-[10px] sm:text-xs">Type 1</span>
              <span className="bg-gray-700 px-2 sm:px-3 md:px-4 py-1 md:py-2 text-[10px] sm:text-xs">1.5L</span>
              <span className="bg-gray-700 px-2 sm:px-3 md:px-4 py-1 md:py-2 text-[10px] sm:text-xs">150.000km</span>
            </div>
          </div>
        </div>
      </div>

      {/* Auction Section */}
      <div className="w-full p-4 sm:p-6 lg:p-8 flex flex-col items-center gap-4 sm:gap-6">
        <div className="flex justify-between w-full max-w-md">
          <div className="flex flex-col items-start">
            <span className="text-[10px] sm:text-xs text-gray-400">Bid Price</span>
            <span className="text-base sm:text-lg font-bold">$200</span>
          </div>
          <div className="flex flex-col items-end bg-gray-700 p-2 sm:p-3 rounded">
            <span className="text-[10px] sm:text-xs text-gray-400">Auction Ends in</span>
            <span className="text-red-500 text-[10px] sm:text-xs font-semibold">13h42m05s</span>
          </div>
        </div>
        <p className="text-[10px] sm:text-xs text-gray-400">Bid $210 or more</p>
        <button
          type="button"
          className="bg-green-400 text-primary font-mono font-semibold py-3 px-8 border-b-4 border-green-700 active:border-b-0 active:translate-y-0.5 hover:bg-green-600 transition-all cursor-pointer w-full max-w-md text-xs sm:text-sm md:text-base"
        >
          CONNECT WALLET
        </button>
        <div className="w-full max-w-md flex flex-col gap-2 pt-4">
          <div className="flex justify-between text-[10px] sm:text-xs">
            <span>@luisburigo</span>
            <span>$200</span>
          </div>
          <div className="flex justify-between text-[10px] sm:text-xs text-gray-400">
            <span>0x01...C3df</span>
            <span>$180</span>
          </div>
          <div className="flex justify-between text-[10px] sm:text-xs text-gray-400">
            <span>@fabioseva</span>
            <span>$150</span>
          </div>
        </div>
      </div>
    </div>
  );
}
