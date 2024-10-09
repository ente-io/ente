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
 * Common props for a nested drawer component. In addition to the regular modal
 * visibility controls for opening and closing itself, these also surface an
 * option to close the entire drawer.
 */
export type NestedDrawerVisibilityProps = ModalVisibilityProps & {
    /**
     * Called when the user wants to close the entire stack of drawers.
     *
     * Note that this does not automatically imply onClose. Each step in the
     * nesting will have to chain their own onCloses to construct a new
     * `onRootClose` suitable for passing to its children.
     */
    onRootClose: () => void;
};
