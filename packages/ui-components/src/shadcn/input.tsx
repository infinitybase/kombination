import * as React from "react"
import { cn } from "../lib/utils" 
import { Search } from "lucide-react"


function Input({ className, type, error, align, textType, ...props }: React.ComponentProps<"input"> & { error?: string, align?: "center", textType?: "success" }) {
  return (
    <div className="w-full relative">
      {type === "search" && <Search className={cn("text-gray-tertiary absolute top-2 left-2", error && "text-danger" )}/>}
      
      <input
        type={type}
        data-slot="input"
        className={cn(
          "file:text-foreground placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 flex h-10 w-full min-w-0 border-4 border-gray-tertiary bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
          "focus-visible:border-gray-tertiary focus-visible:ring-ring/20 focus-visible:ring-[3px]",
          "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
          className,
          type === "search" && "ps-8",
          textType === "success" && "text-success",
          error && "border-danger text-danger focus-visible:border-danger focus-visible:ring-danger/50",
          align === "center" && "text-center"
        )}
        {...props}
      />
      {error && <span className="text-danger text-label">{error}</span>}
    </div>
  )
}

export { Input }
