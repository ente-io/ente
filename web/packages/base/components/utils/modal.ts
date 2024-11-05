import { useCallback, useState } from "react";

/**
 * Common props that control the display of a modal (e.g. dialog, drawer)
 * component.
 */
export interface ModalVisibilityProps {
    /** If `true`, the component is shown. */
    open: boolean;
    /** Callback fired when the component requests to be closed. */
    onClose: () => void;
}

/**
 * A convenience hook for keeping the state for opening and closing a modal, and
 * exposing a function to close the modal whose identity is stable.
 *
 * These props can be passed verbatim to our components that expect
 * {@link ModalVisibilityProps}.
 */
export const useModalVisibility = () => {
    const [open, setOpen] = useState(false);

    const show = useCallback(() => setOpen(true), []);
    const onClose = useCallback(() => setOpen(false), []);

    return { show, props: { open, onClose } };
};
