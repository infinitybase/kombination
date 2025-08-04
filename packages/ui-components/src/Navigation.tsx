import { Button } from "./shadcn/button";
import Logo4 from './assets/logo-variant-4.svg';
import AutoParts from './assets/icons/autoparts-hover.svg';
import Garage from './assets/icons/garage-hover.svg';
import BarnFinds from './assets/icons/barn-finds-hover.svg';

export function Navigation() {
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
    <nav className="w-full flex justify-center bg-beige-primary">
      <div className="w-full max-w-[1600px] flex items-center justify-between p-2 md:p-4 md:px-12 h-[5rem]">
        <img src={Logo4} alt="Kombination logo" className="h-auto max-w-[5rem] hidden md:block"/>

        <ul className="w-full md:size-fit grid grid-cols-3 gap-2">
          {navlinks.map(link => (
            <li key={link.title}>
              <Button className="w-full bg-transparent text-gray-primary flex flex-col md:flex-row md:gap-3 items-center text-xs">
                <img src={link.icon} className="h-[2rem] md:h-[1rem]" />
                {link.title}
              </Button>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}