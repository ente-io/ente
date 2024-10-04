import { DialogTitle, styled } from "@mui/material";

/**
 * A DialogTitle component that resets global {@link DialogTitle} padding
 * overrides.
 *
 * This component is not meant for use in particular, but rather serves as a
 * documentation point. There are following global styleOverrides that affect
 * the layout of content within the Dialog:
 *
 *     "& .MuiDialogTitle-root": {
 *         padding: "16px",
 *     },
 *     "& .MuiDialogContent-root": {
 *         padding: "16px",
 *         overflowY: "overlay",
 *     },
 *     "& .MuiDialogActions-root": {
 *         padding: "16px",
 *     },
 *     ".MuiDialogTitle-root + .MuiDialogContent-root": {
 *         paddingTop: "16px",
 *     },
 *
 * However, in practice, each dialog ends up being bespoke to some extent, and
 * these global overrides come in the way. For now, one approach we can try is
 * to reset this padding whenever possible, so that in the future we can modify
 * the global defaults (or remove them altogether).
 */
export const DialogTitleV3 = styled(DialogTitle)`
    "&&&": {
        padding: 0;
    }
`;
