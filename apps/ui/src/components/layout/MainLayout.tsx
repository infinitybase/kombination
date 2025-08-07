import type { ReactNode } from "react";
import { Header } from "../Header";

interface IMainLayoutProps {
  children: ReactNode
}

export function MainLayout({ children }: IMainLayoutProps) {
  return (
    <div className="p-0 xs:py-4 h-page-height">
      <Header />

      <main 
        className="w-full h-full flex flex-col-reverse items-center lg:flex-col bg-yellow-light text-white font-mono max-w-screen"
      >
        {children}
      </main>
    </div>
  )
}