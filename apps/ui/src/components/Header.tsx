import { Button } from '@kombination/ui-components/shadcn/button.js';
import Logo from '@kombination/ui-components/assets/logo-variant-5.svg';
import AutoParts from '@kombination/ui-components/assets/icons/autoparts.svg';
import Garage from '@kombination/ui-components/assets/icons/garage.svg';
import BarnFinds from '@kombination/ui-components/assets/icons/barn-finds.svg';

export function Header() {
  const navlinks = [
    {
      title: "Barn Finds",
      link: '/barn-finds',
      icon: BarnFinds
    },
    {
      title: " Auto Parts",
      link: '/auto-parts',
      icon: AutoParts
    },
    {
      title: "Garage",
      link: '/garage',
      icon: Garage
    }
  ] as const

  return (
    <nav className="w-full flex justify-center bg-gray-tertiary">
      <div className="w-full max-w-max-width flex items-center justify-between p-2 md:p-4 md:px-12 h-header">
        <img src={Logo} alt="Kombination logo" className="h-auto max-w-header hidden md:block" />

        <ul className="w-full md:size-fit grid grid-cols-3 gap-2">
          {navlinks.map(link => (
            <li key={link.title}>
              <Button variant="ghost" size="sm" className="w-full text-beige-light flex flex-col md:flex-row md:gap-3 items-center">
                <img src={link.icon} className="h-[2rem] md:h-[1rem] text-beige-light" />
                {link.title}
              </Button>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}