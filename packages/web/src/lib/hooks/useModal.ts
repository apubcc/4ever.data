import { useState } from "react";

export function useModal() {
  const [isOpen, setIsOpen] = useState<boolean>(false);

  const toggleModal = () => {
    setIsOpen((state) => !state);
  };

  return [isOpen, toggleModal];
}
