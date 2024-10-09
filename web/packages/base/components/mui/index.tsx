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
