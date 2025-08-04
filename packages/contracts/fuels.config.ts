import { createConfig } from "fuels";

// @TODO: Consider moving this to a package like @packages/shared
const requireEnv = (name: string) => {
  // The environment variables are not needed when building the contracts
  const isBuilding = process.argv.includes("build");
  if (isBuilding) return undefined;

  const value = process.env[name];
  if (!value) {
    throw new Error(`Environment variable ${name} is not set`);
  }
  return value;
};

export default createConfig({
  workspace: "./sway",
  output: "./src/artifacts",
  providerUrl: requireEnv("FUEL_PROVIDER_URL"),
  privateKey: requireEnv("FUEL_PRIVATE_KEY"),
});
