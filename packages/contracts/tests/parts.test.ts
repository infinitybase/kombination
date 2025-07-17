import { describe, it, beforeAll, afterAll, expect } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import { Identity, callAndWait, get } from "./utils";
import { PartsNftFactory } from "../src";
import { AccessoryTypeOutput } from "../src/artifacts/contracts/PartsNft";
import { DateTime } from "fuels";

const testSetup = async () => {
  const node = await launchTestNode();

  const { wallets, provider } = node;
  const [wallet] = wallets;
  const deploy = await PartsNftFactory.deploy(wallet, {
    configurableConstants: {
      INITIAL_OWNER: Identity.address(wallet),
    },
  });
  const { contract } = await deploy.waitForResult();

  await callAndWait(contract.functions.constructor(Identity.address(wallet)));

  const nexDay = async () => {
    const block = await provider.getBlock("latest");
    if (!block) throw new Error("Block not found");

    const timestamp = DateTime.fromTai64(block.time).toUnixMilliseconds();

    await provider.produceBlocks(3, timestamp + 1 * 24 * 60 * 60 * 1000);
  };

  return {
    contract,
    wallet,
    nexDay,
    ...node,
  };
};

type TestSetup = Awaited<ReturnType<typeof testSetup>>;

describe("PartsNft", () => {
  let setup: TestSetup;

  beforeAll(async () => {
    setup = await testSetup();
  });

  afterAll(async () => {
    setup.cleanup();
  });

  it("should get accessory of day", async () => {
    const { contract } = setup;

    const { value: day1 } = await callAndWait(
      contract.functions.acessory_of_day(),
    );
    expect(day1).toBe(AccessoryTypeOutput.Item);

    await setup.nexDay();

    const { value: day2 } = await callAndWait(
      contract.functions.acessory_of_day(),
    );
    expect(day2).toBe(AccessoryTypeOutput.Wheels);

    await setup.nexDay();

    const { value: day3 } = await callAndWait(
      contract.functions.acessory_of_day(),
    );
    expect(day3).toBe(AccessoryTypeOutput.PaintJob);

    await setup.nexDay();

    const { value: day4 } = await callAndWait(
      contract.functions.acessory_of_day(),
    );
    expect(day4).toBe(AccessoryTypeOutput.Item);
  });
});
