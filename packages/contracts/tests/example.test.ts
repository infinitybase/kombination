import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import { type KombinationExample, KombinationExampleFactory } from "../src";
import { callAndWait } from "./utils";

const setup = async () => {
  const node = await launchTestNode({
    contractsConfigs: [{ factory: KombinationExampleFactory }],
  });

  const { contracts, wallets } = node;
  const [wallet] = wallets;
  const [kombination] = contracts;

  return {
    contract: kombination as KombinationExample,
    wallet,
    ...node,
  };
};

describe("Slots", async () => {
  let testSetup: Awaited<ReturnType<typeof setup>>;

  beforeAll(async () => {
    testSetup = await setup();
  });

  afterAll(async () => {
    testSetup.cleanup();
  });

  test("should call test_function correctly", async () => {
    const { contract } = testSetup;

    const result = await callAndWait(contract.functions.test_function());

    expect(result.value).toBe(true);
  });
});
