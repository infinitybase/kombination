import { B256Coder, BigNumberCoder, sha256, TupleCoder } from "fuels";

// sha256(PART)
export const PART_PREFIX =
  "0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc";

// sha256(KOMBI)
export const KOMBI_PREFIX =
  "0x390643a7ea067800e503b0510f4a6e3f1cc9b114b09dd9d140553f76a19a0620";

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
  private coder: TupleCoder<[B256Coder, BigNumberCoder]>;

  constructor() {
    this.coder = new TupleCoder([new B256Coder(), new BigNumberCoder("u64")]);
  }

  encode(partId: number) {
    return this.coder.encode([PART_PREFIX, partId]);
  }

  encodeSha256(partId: number) {
    return sha256(this.encode(partId));
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
