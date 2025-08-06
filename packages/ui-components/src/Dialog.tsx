import { ReactNode } from 'react';
import { 
  Dialog as DialogComponent,
  DialogContent, 
  DialogDescription, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from './shadcn/dialog';

interface IDialogProps {
  title?: string
  children: ReactNode
  isOpen: boolean
  setIsOpen: (value: boolean) => void
}

export function Dialog({ title, children, isOpen, setIsOpen }: IDialogProps) {
  return (
    <DialogComponent open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        {children}
      </DialogContent>
    </DialogComponent>
  )
}