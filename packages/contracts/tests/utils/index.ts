import type { FunctionInvocationScope, MultiCallInvocationScope } from "fuels";

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
