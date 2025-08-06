import type { AuctionData } from "@/features/barn-finds/types";

export const auctionsMock: AuctionData[] = [
  {
    id_auction: 1,
    name: "Kombi 1979",
    description: "Fresh from the barn, this '78 T2 Kombi is ready for a second life. Dressed in faded orange, it Proudly features a custom sunroof, making it a true revival masterpiece.",
    infos: [
      "Type 1",
      "1.5L",
      "150.000km"
    ],
    category: "barn",
    isClosed: true,
    winner: "@ferrabacal",
    date: new Date('2025-08-04'),
    currentBidAmount: 210,
    bids: [
      {
        name: "@luisburigo",
        amount: 200
      },
      {
        name: "0x01...C3df",
        amount: 180
      },
      {
        name: "@fabioseva",
        amount: 150
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "@ferabacal",
        amount: 210
      },
    ]
  },
  {
    id_auction: 2,
    name: "Kombi Scooby Doo",
    description: "Fresh from the barn, this '78 T2 Kombi is ready for a second life. Dressed in faded orange, it proudly features a custom sunroof, making it a true revival masterpiece.",
    infos: [
      "Type 2",
      "2L",
      "50.000km"
    ],
    category: "barn",
    date: new Date(),
    isClosed: false,
    winner: null,
    currentBidAmount: 210,
    bids: [
      {
        name: "@luisburigo",
        amount: 200
      },
      {
        name: "0x01...C3df",
        amount: 180
      },
      {
        name: "@fabioseva",
        amount: 150
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "1x83...F482",
        amount: 130
      },
      {
        name: "@ferabacal",
        amount: 210
      },
    ]
  },
];