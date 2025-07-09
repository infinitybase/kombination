import {
  B256Coder,
  BigNumberCoder,
  NumberCoder,
  sha256,
  TupleCoder,
} from "fuels";

// sha256(PART)
export const PART_PREFIX =
  "0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc";

// sha256(KOMBI)
export const KOMBI_PREFIX =
  "0x390643a7ea067800e503b0510f4a6e3f1cc9b114b09dd9d140553f76a19a0620";

export enum Part {
  HeadLight = 0,
  Bumper = 1,
  Antenna = 2,
  Mirror = 3,
  Screens = 4,
  SideStep = 5,
}

export class KombiTypeSubIDCoder {
  private coder: TupleCoder<[B256Coder, BigNumberCoder]>;

  constructor() {
    this.coder = new TupleCoder([new B256Coder(), new BigNumberCoder("u64")]);
  }

  encode(kombiTypeId: number) {
    return this.coder.encode([KOMBI_PREFIX, kombiTypeId]);
  }

  encodeSha256(kombiTypeId: number) {
    return sha256(this.encode(kombiTypeId));
  }
}

export class PartSubIDCoder {
  private coder: TupleCoder<[B256Coder, NumberCoder, BigNumberCoder]>;

  constructor() {
    this.coder = new TupleCoder([
      new B256Coder(),
      new NumberCoder("u8"),
      new BigNumberCoder("u64"),
    ]);
  }

  encode(part: Part, partId: number) {
    return this.coder.encode([PART_PREFIX, part, partId]);
  }

  encodeSha256(part: Part, partId: number) {
    return sha256(this.encode(part, partId));
  }
}

export class KombiAssetIDCoder {
  private coder: TupleCoder<[B256Coder, BigNumberCoder]>;

  constructor() {
    this.coder = new TupleCoder([new B256Coder(), new BigNumberCoder("u64")]);
  }

  encode(kombiTypeId: string, subId: number) {
    return this.coder.encode([kombiTypeId, subId]);
  }

  encodeSha256(kombiTypeId: string, subId: number) {
    return sha256(this.encode(kombiTypeId, subId));
  }
}
