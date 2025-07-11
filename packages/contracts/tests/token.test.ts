import { describe, it, expect, beforeEach, beforeAll } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import { AssetId, Identity, callAndWait, get } from "./utils";
import { KombiNftFactory } from "../src";
import { ComponentTypeInput } from "../src/artifacts/contracts/KombiNft";
import { bn } from "fuels";

const BASE_URI = "https://kombi.com/";

const testSetup = async () => {
  const node = await launchTestNode();

  const { wallets } = node;
  const [wallet] = wallets;

  const configurables = {
    INITIAL_OWNER: Identity.address(wallet),
    NAME: "Kombination",
    SYMBOL: "KMB",
  };
  const deploy = await KombiNftFactory.deploy(wallet, {
    configurableConstants: configurables,
  });
  const { contract } = await deploy.waitForResult();

  await callAndWait(
    contract.functions.constructor(Identity.address(wallet), BASE_URI),
  );

  return {
    contract,
    wallet,
    configurables,
    ...node,
  };
};

type TestSetup = Awaited<ReturnType<typeof testSetup>>;

describe("KombiNft", () => {
  let setup: TestSetup;

  beforeAll(async () => {
    setup = await testSetup();
  });

  it("should register components", async () => {
    const { contract } = setup;
    const componentes = Object.values(ComponentTypeInput);

    for (const componente of componentes) {
      await callAndWait(contract.functions.add_component(componente, "test"));
    }

    for (const componente of componentes) {
      const component = await get(contract.functions.get_component(componente));
      expect(component).toBeDefined();
      expect(component?.toString()).toBe("1");
    }
  });

  it("should mint a token", async () => {
    const { contract, wallet } = setup;

    await callAndWait(contract.functions.mint(Identity.address(wallet)));

    const assetId = AssetId.new(contract, bn(0).toHex(32));
    const balance = await wallet.getBalance(assetId);
    expect(balance.toString()).toBe("1");

    const [uri, image] = await get(
      contract.multiCall([
        contract.functions.metadata(AssetId.toBits(assetId), "uri"),
        contract.functions.metadata(AssetId.toBits(assetId), "image"),
      ]),
    );

    expect(uri?.String).toBe(`${BASE_URI}${assetId}/metadata.json`);
    expect(image?.String).toBe(`${BASE_URI}${assetId}/image.png`);
  });
});
