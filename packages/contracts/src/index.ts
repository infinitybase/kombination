export * from "./artifacts";
export * from "./coders";

export type Enum<T> = {
  [K in keyof T]: Pick<T, K> & { [P in Exclude<keyof T, K>]?: never };
}[keyof T];

export enum PartTypeOutput {
  HeadLight = "HeadLight",
  Bumper = "Bumper",
  Antenna = "Antenna",
  Mirror = "Mirror",
  Screens = "Screens",
  SideStep = "SideStep",
}

export type AssetType = Enum<{ Kombi: void; Part: PartTypeOutput }>;
