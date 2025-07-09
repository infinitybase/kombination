import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { launchTestNode } from "fuels/test-utils";
import {
  KombinationTokenFactory,
  PartSubIDCoder,
  KombiTypeSubIDCoder,
  KombiAssetIDCoder,
  Part,
} from "../src";
import { Address, AssetId, callAndWait, get, Identity } from "./utils";
import {
  PartTypeInput,
  PartTypeOutput,
} from "../src/artifacts/contracts/KombinationToken";

const KOMBI_METADATA = {
  bg_image: "https://example.com",
  image: "https://example.com",
  uri: "https://example.com/1.json",
  name: "Kombi Type 1",
  description: "Kombi Type 1 Description",
};

const PART_METADATA = {
  bg_image: "https://example.com",
  image: "https://example.com",
  uri: "https://example.com/1.json",
  kombi_type_id: undefined,
};

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

const kombiTypeSubIDCoder = new KombiTypeSubIDCoder();
const partSubIDCoder = new PartSubIDCoder();
const kombiAssetIDCoder = new KombiAssetIDCoder();

describe("KombinationToken - Asset", async () => {
  let testSetup: Awaited<ReturnType<typeof setup>>;

  beforeAll(async () => {
    testSetup = await setup();
  });

  afterAll(async () => {
    testSetup.cleanup();
  });

  test("should register kombi type correctly", async () => {
    const { contract } = testSetup;

    const result = await callAndWait(
      contract.functions.register_kombi_type(KOMBI_METADATA),
    );

    const registeredEvent = result.logs[result.logs.length - 1];
    const expectedKombiTypeSubID = kombiTypeSubIDCoder.encodeSha256(0);

    expect(registeredEvent.kombi_id.toNumber()).toEqual(0);
    expect(registeredEvent.sub_id).toEqual(expectedKombiTypeSubID);
  });

  test("should register part correctly", async () => {
    const { contract } = testSetup;

    const kombiTypeSubID = kombiTypeSubIDCoder.encodeSha256(0);
    const result = await callAndWait(
      contract.functions.register_part(PartTypeInput.Antenna, {
        ...PART_METADATA,
        kombi_type_id: kombiTypeSubID,
      }),
    );

    const partRegisteredEvent = result.logs[result.logs.length - 1];
    const expectedPartSubID = partSubIDCoder.encodeSha256(Part.Antenna, 0);

    expect(partRegisteredEvent.part_id.toNumber()).toEqual(0);
    expect(partRegisteredEvent.sub_id).toEqual(expectedPartSubID);
  });

  test("should get part type correctly", async () => {
    const { contract } = testSetup;

    let partType = await get(
      contract.functions.get_part_type(
        partSubIDCoder.encodeSha256(Part.Antenna, 0),
      ),
    );
    expect(partType).toBe(PartTypeOutput.Antenna);

    partType = await get(
      contract.functions.get_part_type(
        partSubIDCoder.encodeSha256(Part.Antenna, 1),
      ),
    );
    expect(partType).toBeUndefined;
  });

  test("should mint kombi correctly", async () => {
    const { contract, wallet } = testSetup;

    const kombiId = kombiTypeSubIDCoder.encodeSha256(0);
    const result = await callAndWait(
      contract.functions.mint_kombi(kombiId, Identity.address(wallet)),
    );
    const assetSubID = kombiAssetIDCoder.encodeSha256(kombiId, 0);
    const expectedAssetId = AssetId.new(contract, assetSubID);
    const mintedEvent = result.logs[result.logs.length - 1];

    expect(mintedEvent.kombi_id).toEqual(kombiId);
    expect(AssetId.fromBits(mintedEvent.asset_id)).toEqual(expectedAssetId);

    const balance = await wallet.getBalance(
      AssetId.fromBits(mintedEvent.asset_id),
    );
    expect(balance.toString()).toBe("1");

    const assetType = await get(
      contract.functions.get_asset_type(AssetId.toBits(expectedAssetId)),
    );

    // @ts-expect-error: assetType of Kombi always return a string
    expect(assetType).toEqual("Kombi");

    const totalKombis = await get(
      contract.functions.get_total_assets_type({ Kombi: undefined }),
    );
    expect(totalKombis.toNumber()).toBe(1);
  });

  test("should mint kombi with same id correctly", async () => {
    const { contract, wallet } = testSetup;

    const kombiId = kombiTypeSubIDCoder.encodeSha256(0);
    await callAndWait(
      contract.functions.mint_kombi(kombiId, Identity.address(wallet)),
    );
    const assetSubID = kombiAssetIDCoder.encodeSha256(kombiId, 1);
    const expectedAssetId = AssetId.new(contract, assetSubID);

    const balance = await wallet.getBalance(expectedAssetId);
    expect(balance.toString()).toBe("1");

    const totalKombis = await get(
      contract.functions.get_total_assets_type({ Kombi: undefined }),
    );
    expect(totalKombis.toNumber()).toBe(2);
  });

  test("should mint part correctly", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(Part.Antenna, 0);

    await callAndWait(
      contract.functions.mint_part(subId, Identity.address(wallet)),
    );

    const mintedAssetId = AssetId.new(contract, subId);
    const balance = await wallet.getBalance(mintedAssetId);
    expect(balance.toString()).toBe("1");

    const assetType = await get(
      contract.functions.get_asset_type(AssetId.toBits(mintedAssetId)),
    );

    // @ts-expect-error: assetType of Part always return a string
    expect(assetType).toEqual({ Part: "Antenna" });

    const totalParts = await get(
      contract.functions.get_total_assets_type({
        Part: PartTypeInput.Antenna,
      }),
    );
    expect(totalParts.toNumber()).toBe(1);
  });

  test("should not mint part twice", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(Part.Antenna, 0);

    await expect(
      callAndWait(
        contract.functions.mint_part(subId, Identity.address(wallet)),
      ),
    ).rejects.toThrow("Part already minted");
  });

  test("should not mint part not registered", async () => {
    const { contract, wallet } = testSetup;
    const subId = partSubIDCoder.encodeSha256(Part.Antenna, 100);

    await expect(
      callAndWait(
        contract.functions.mint_part(subId, Identity.address(wallet)),
      ),
    ).rejects.toThrow("Part not registered");
  });

  test("should get metadata correctly", async () => {
    const { contract } = testSetup;

    const kombiId = kombiTypeSubIDCoder.encodeSha256(0);
    const kombiSubId = kombiAssetIDCoder.encodeSha256(kombiId, 0);
    const kombiAssetId = AssetId.bits(contract, kombiSubId);

    for (const key of Object.keys(KOMBI_METADATA)) {
      const metadata = await get(
        contract.functions.metadata(kombiAssetId, key),
      );
      expect(metadata?.String).toBe(KOMBI_METADATA[key]);
    }

    const partSubId = partSubIDCoder.encodeSha256(Part.Antenna, 0);
    const partAssetId = AssetId.bits(contract, partSubId);
    const partMetadata = {
      ...PART_METADATA,
      kombi_type_id: kombiId,
    };

    for (const key of Object.keys(partMetadata)) {
      const metadata = await get(contract.functions.metadata(partAssetId, key));
      expect(metadata?.String ?? metadata?.B256).toBe(partMetadata[key]);
    }
  });

  test("should execute SRC20 methods correctly", async () => {
    const { contract, configurables } = testSetup;

    const subId = partSubIDCoder.encodeSha256(Part.Antenna, 0);
    const assetId = AssetId.bits(contract, subId);

    const name = await get(contract.functions.name(assetId));
    expect(name).toBe(configurables.NAME);

    const symbol = await get(contract.functions.symbol(assetId));
    expect(symbol).toBe(configurables.SYMBOL);

    const decimals = await get(contract.functions.decimals(assetId));
    expect(decimals).toBe(0);
  });
});

describe("KombinationToken - Part Attachment", async () => {
  let testSetup: Awaited<ReturnType<typeof setup>>;

  const kombiIds = [
    kombiTypeSubIDCoder.encodeSha256(0),
    kombiTypeSubIDCoder.encodeSha256(1),
  ];

  const partIds = [
    partSubIDCoder.encodeSha256(Part.Antenna, 0),
    partSubIDCoder.encodeSha256(Part.Antenna, 1),
    partSubIDCoder.encodeSha256(Part.Bumper, 0),
  ];

  let kombiAssetIds: string[] = [];
  let partAssetIds: string[] = [];

  beforeAll(async () => {
    testSetup = await setup();
    const { contract, wallet } = testSetup;

    await callAndWait(contract.functions.register_kombi_type(KOMBI_METADATA));
    await callAndWait(contract.functions.register_kombi_type(KOMBI_METADATA));

    await callAndWait(
      contract.functions.register_part(PartTypeInput.Antenna, {
        ...PART_METADATA,
        kombi_type_id: kombiIds[0],
      }),
    );
    await callAndWait(
      contract.functions.register_part(PartTypeInput.Antenna, {
        ...PART_METADATA,
        kombi_type_id: kombiIds[0],
      }),
    );
    await callAndWait(
      contract.functions.register_part(PartTypeInput.Bumper, {
        ...PART_METADATA,
        kombi_type_id: kombiIds[1],
      }),
    );

    const batchPartMint = partIds.map((id) =>
      contract.functions.mint_part(id, Identity.address(wallet)),
    );
    await callAndWait(contract.multiCall(batchPartMint));

    const batchKombiMint = kombiIds.map((id) =>
      contract.functions.mint_kombi(id, Identity.address(wallet)),
    );
    await callAndWait(contract.multiCall(batchKombiMint));

    kombiAssetIds = kombiIds.map((id) => {
      const subId = kombiAssetIDCoder.encodeSha256(id, 0);
      return AssetId.new(testSetup.contract, subId);
    });
    partAssetIds = partIds.map((id) => AssetId.new(testSetup.contract, id));
  });

  afterAll(async () => {
    testSetup.cleanup();
  });

  test("should attach part to kombi correctly", async () => {
    const { contract, wallet } = testSetup;

    const kombiAssetId = AssetId.toBits(kombiAssetIds[0]);
    const partAssetId = AssetId.toBits(partAssetIds[0]);

    const { logs } = await callAndWait(
      contract.functions.attach_part(kombiAssetId).callParams({
        forward: {
          amount: 1,
          assetId: partAssetId.bits,
        },
      }),
    );

    const partAttachedEvent = logs[logs.length - 1];
    expect(partAttachedEvent.part_id).toEqual(partIds[0]);
    expect(partAttachedEvent.kombi_id).toEqual(kombiIds[0]);
    expect(partAttachedEvent.part_type).toEqual(PartTypeOutput.Antenna);
    expect(partAttachedEvent.owner).toEqual(Identity.address(wallet));

    const balance = await wallet.getBalance(partAssetId.bits);
    expect(balance.toString()).toBe("0");

    // On attachment, the part is burned and cannot be minted a new part again
    await expect(
      callAndWait(
        contract.functions.mint_part(partIds[0], Identity.address(wallet)),
      ),
    ).rejects.toThrow("Part already minted");
  });

  test("should get part attached to kombi correctly", async () => {
    const { contract } = testSetup;

    const kombiAssetId = AssetId.toBits(kombiAssetIds[0]);
    const partAssetId = AssetId.toBits(partAssetIds[0]);

    const partAttached = await get(
      contract.functions.is_part_attached_to_kombi(partAssetId),
    );

    if (!partAttached) {
      throw new Error("Part not attached to kombi");
    }

    expect(AssetId.fromBits(partAttached)).toEqual(
      AssetId.fromBits(kombiAssetId),
    );

    const kombiParts = await get(
      contract.functions.get_kombi_parts(kombiAssetId, PartTypeInput.Antenna),
    );
    if (!kombiParts) {
      throw new Error("Kombi parts not found");
    }
    expect(AssetId.fromBits(kombiParts)).toEqual(AssetId.fromBits(partAssetId));
  });

  test("should error on attach part to wrong kombi type", async () => {
    const { contract } = testSetup;

    const kombiAssetId = AssetId.toBits(kombiAssetIds[0]);
    const partAssetId = AssetId.toBits(partAssetIds[2]);

    await expect(
      callAndWait(
        contract.functions.attach_part(kombiAssetId).callParams({
          forward: {
            amount: 1,
            assetId: partAssetId.bits,
          },
        }),
      ),
    ).rejects.toThrow("Part is not compatible with this kombi type");

    const partKombiType = await get(
      contract.functions.metadata(partAssetId, "kombi_type_id"),
    );
    expect(partKombiType?.B256).toBe(kombiIds[1]);
  });

  test("should error on attach part when the kombi already has a part", async () => {
    const { contract } = testSetup;

    const kombiAssetId = AssetId.toBits(kombiAssetIds[0]);
    const partAssetId = AssetId.toBits(partAssetIds[1]);

    await expect(
      callAndWait(
        contract.functions.attach_part(kombiAssetId).callParams({
          forward: {
            amount: 1,
            assetId: partAssetId.bits,
          },
        }),
      ),
    ).rejects.toThrow("Kombi already has a part");
  });

  test("should detach part from kombi correctly", async () => {
    const { contract, wallet } = testSetup;

    const kombiAssetId = AssetId.toBits(kombiAssetIds[0]);
    const partAssetId = AssetId.toBits(partAssetIds[0]);

    const { logs } = await callAndWait(
      contract.functions.detach_part(partAssetId).callParams({
        forward: {
          amount: 1,
          assetId: kombiAssetId.bits,
        },
      }),
    );

    const partDetachedEvent = logs[logs.length - 1];
    expect(partDetachedEvent.part_id).toEqual(partIds[0]);
    expect(partDetachedEvent.kombi_id).toEqual(kombiIds[0]);
    expect(partDetachedEvent.part_type).toEqual(PartTypeOutput.Antenna);
    expect(partDetachedEvent.owner).toEqual(Identity.address(wallet));

    const balance = await wallet.getBalance(partAssetId.bits);
    expect(balance.toString()).toBe("1");

    const partAttached = await get(
      contract.functions.is_part_attached_to_kombi(partAssetId),
    );
    expect(partAttached).toBeUndefined();

    const kombiParts = await get(
      contract.functions.get_kombi_parts(kombiAssetId, PartTypeInput.Antenna),
    );
    expect(kombiParts).toBeUndefined();
  });
});
