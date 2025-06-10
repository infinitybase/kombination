import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import { KombinationTokenFactory } from "../src";
import { Address, AssetId, callAndWait, get, Identity } from "./utils";
import {
  PartTypeInput,
  PartTypeOutput,
} from "../src/artifacts/contracts/KombinationToken";
import { B256Coder, BigNumberCoder, sha256, TupleCoder } from "fuels";

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

  const configurables = {
    INITIAL_OWNER: Address.bits(wallet),
    NAME: "Kombination",
    SYMBOL: "KMB",
  };
  const deploy = await KombinationTokenFactory.deploy(wallet, {
    configurableConstants: configurables,
  });
  const { contract } = await deploy.waitForResult();

  return {
    contract,
    wallet,
    configurables,
    ...node,
  };
};

describe("KombinationToken", async () => {
  const partSubIDCoder = new PartSubIDCoder();

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
    const partSubID = partSubIDCoder.encodeSha256(0);

    expect(partSubID).toEqual(expectedPartSubID);
  });

  test("should get part type correctly", async () => {
    const { contract } = testSetup;

    let partType = await get(
      contract.functions.get_part_type(partSubIDCoder.encodeSha256(0)),
    );
    expect(partType).toBe(PartTypeOutput.Antenna);

    partType = await get(
      contract.functions.get_part_type(partSubIDCoder.encodeSha256(1)),
    );
    expect(partType).toBeUndefined;
  });

  test("should mint part correctly", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(0);

    await callAndWait(
      contract.functions.mint_part(subId, Identity.address(wallet)),
    );

    const mintedAssetId = AssetId.new(contract, subId);
    const balance = await wallet.getBalance(mintedAssetId);
    expect(balance.toString()).toBe("1");
  });

  test("should not mint part twice", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(0);

    await expect(
      callAndWait(
        contract.functions.mint_part(subId, Identity.address(wallet)),
      ),
    ).rejects.toThrow("Part already minted");
  });

  test("should not mint part not registered", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(100);

    await expect(
      callAndWait(
        contract.functions.mint_part(subId, Identity.address(wallet)),
      ),
    ).rejects.toThrow("Part not registered");
  });

  test("should execute SRC20 methods correctly", async () => {
    const { contract, configurables } = testSetup;

    const subId = partSubIDCoder.encodeSha256(0);
    const assetId = AssetId.bits(contract, subId);

    const name = await get(contract.functions.name(assetId));
    expect(name).toBe(configurables.NAME);

    const symbol = await get(contract.functions.symbol(assetId));
    expect(symbol).toBe(configurables.SYMBOL);

    const decimals = await get(contract.functions.decimals(assetId));
    expect(decimals).toBe(0);
  });
});
