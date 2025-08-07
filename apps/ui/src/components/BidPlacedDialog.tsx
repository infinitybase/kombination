import { Dialog } from "@kombination/ui-components/Dialog.js";
import { Button } from "@kombination/ui-components/shadcn/button.js";
import { Input } from "@kombination/ui-components/shadcn/input.js";

interface IBidPlacedDialog {
  isOpen: boolean
  setIsOpen: (value: boolean) => void
}

export function BidPlacedDialog({ isOpen, setIsOpen}: IBidPlacedDialog) {
  function handleCloseDialog() {
    setIsOpen(false)
  }

  function handleNotifyByEmail() {
    // TODO
    setIsOpen(false)
  }

  return (
    <Dialog title="Bid Placed!" isOpen={isOpen} setIsOpen={setIsOpen}>
      <div className="flex flex-col gap-6">
        <p className="text-beige-light text-center mt-12">Don't lose the lead, turn on notifications to know if someone outbids you!</p>

        <div className="w-full flex items-stretch gap-3">
          <Input 
            id="email" 
            type="email" 
            placeholder="notify by e-mail" 
            className="flex-1 text-success"
            align="center"
            />
          <Button variant="success" onClick={handleNotifyByEmail}>OK</Button>
        </div>

        <Button className="w-full mt-12" onClick={handleCloseDialog}>Skip</Button>
      </div>
    </Dialog>
  )
}