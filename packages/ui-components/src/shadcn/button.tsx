import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../lib/utils"
import { ChevronLeft, ChevronRight, Pencil, PlusIcon } from "lucide-react"

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-1 whitespace-nowrap text-sm font-medium transition-all text-gray-primary disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-5 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive cursor-pointer border-b-4",
  {
    variants: {
      variant: {
        default:
          "bg-gray-tertiary shadow-xs border-gray-700  hover:bg-gray-secondary/90",
        destructive:
          "bg-destructive text-white shadow-xs hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
        outline:
          "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50",
        success:
          "bg-success shadow-xs border-green-700  hover:bg-green-600",
        danger:
          "bg-danger shadow-xs border-red-800  hover:bg-red-600",
        warning:
          "bg-warning shadow-xs border-yellow-800  hover:bg-yellow-600",
        ghost:
          "hover:text/50 border-none dark:hover:text/30",
        link: "border-none underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2 has-[>svg]:px-3",
        sm: "h-9 gap-1.5 px-3 has-[>svg]:px-2.5 text-xs text-primary",
        lg: "h-11 px-6 has-[>svg]:px-4",
        icon: "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Button({
  className,
  variant,
  children,
  size,
  iconType,
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean,
    iconType?: "add" | "link" | "next" | "edit" | "previous"
  }) {
  const Comp = asChild ? Slot : "button"

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    >
      {iconType === "previous" && <ChevronLeft />}
      {iconType === "add" && <PlusIcon />}
      
      {children}

      {iconType === "next" && <ChevronRight />}
      {iconType === "edit" && <Pencil />}
    </Comp>  
  )
}

export { Button, buttonVariants }
