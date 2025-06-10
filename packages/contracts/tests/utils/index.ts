import {
  type Account,
  getMintedAssetId,
  type FunctionInvocationScope,
  type MultiCallInvocationScope,
  type Contract,
} from "fuels";

export const get = async <T extends unknown[], R>(
  method: FunctionInvocationScope<T, R> | MultiCallInvocationScope<R>,
) => {
  const { value } = await method.get();
  return value;
};

export const callAndWait = async <T extends unknown[], R>(
  method: FunctionInvocationScope<T, R> | MultiCallInvocationScope<R>,
) => {
  const result = await method.call();
  return result.waitForResult();
};

export const Identity = {
  address: (account: string | Account) => {
    return {
      Address: {
        bits: typeof account === "string" ? account : account.address.toB256(),
      },
    };
  },
};

export const AssetId = {
  new: (contract: Contract, subId: string) => {
    return getMintedAssetId(contract.id.toB256(), subId);
  },
};
