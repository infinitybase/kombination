import Logo from '@kombination/ui-components/assets/logo-variant-5.svg';
import AutoParts from '@kombination/ui-components/assets/icons/autoparts.svg';
import Garage from '@kombination/ui-components/assets/icons/garage.svg';
import BarnFinds from '@kombination/ui-components/assets/icons/barn-finds.svg';
import { Link, linkOptions } from '@tanstack/react-router';

const DEFAULT_ACTIVE_CLASS = "underline";

const headerMenuItems = [
  linkOptions({
    to: "/barn-finds",
    label: "Barn Finds",
    activeProps: {
      className: DEFAULT_ACTIVE_CLASS,
    },
    exact: true,
    activeOptions: { exact: true },
    icon: BarnFinds
  }),
  linkOptions({
    to: "/autoparts",
    label: "Auto Parts",
    activeProps: {
      className: DEFAULT_ACTIVE_CLASS,
    },
    activeOptions: { exact: false },
    icon: AutoParts
  }),
  linkOptions({
    to: "/garage",
    label: "Garage",
    activeProps: {
      className: DEFAULT_ACTIVE_CLASS,
    },
    activeOptions: { exact: false },
    icon: Garage
  }),
];

export function Header() {

  return (
    <nav className="w-full flex justify-center bg-gray-tertiary">
      <div className="w-full max-w-max-width flex items-center justify-between p-2 md:p-4 md:px-12 h-header">
        <img src={Logo} alt="Kombination logo" className="h-auto max-w-header hidden md:block" />

        <ul className="w-full md:size-fit grid grid-cols-3 gap-8">
          {headerMenuItems.map(option => (
            <li key={option.to}>
              <Link 
                to={option.to} 
                className="w-full text-beige-light flex flex-col md:flex-row md:gap-3 items-center"
                activeProps={option.activeProps}
                activeOptions={option.activeOptions}
                >
                <img src={option.icon} className="h-[2rem] md:h-[1rem] text-beige-light" />
                {option.label}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}