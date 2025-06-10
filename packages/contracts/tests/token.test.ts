import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import { KombinationTokenFactory } from "../src";
import { callAndWait } from "./utils";
import { PartTypeInput } from "../src/artifacts/contracts/KombinationToken";
import { B256Coder, BigNumberCoder, BNInput, sha256, TupleCoder } from "fuels";

const PART_PREFIX =
  "0x05aa3ac8d365559e81f8ad1b62918aedeabeaebab553e7b129ae95d9acdb77cc";

class PartSubIDCoder {
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

const setup = async () => {
  const node = await launchTestNode();

  const { wallets } = node;
  const [wallet] = wallets;

  const deploy = await KombinationTokenFactory.deploy(wallet);
  const { contract } = await deploy.waitForResult();

  return {
    contract,
    wallet,
    ...node,
  };
};

describe("KombinationToken", async () => {
  let testSetup: Awaited<ReturnType<typeof setup>>;

  beforeAll(async () => {
    testSetup = await setup();
  });

  afterAll(async () => {
    testSetup.cleanup();
  });

  test("should register part correctly", async () => {
    const { contract } = testSetup;

    const result = await callAndWait(
      contract.functions.register_part(PartTypeInput.Antenna, {
        bg_image: "https://example.com",
        image: "https://example.com",
        uri: "https://example.com/1.json",
      }),
    );

    const expectedPartSubID = result.logs[0];
    const partSubIDCoder = new PartSubIDCoder();
    const partSubID = partSubIDCoder.encodeSha256(0);

    expect(partSubID).toEqual(expectedPartSubID);
  });
});
