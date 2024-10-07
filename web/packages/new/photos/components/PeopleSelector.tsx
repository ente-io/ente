import { useIsMobileWidth } from "@/base/hooks";
import { Dialog } from "@mui/material";
import React from "react";
import type { DialogVisibilityProps } from "./mui/Dialog";

type PeopleSelectorProps = DialogVisibilityProps;

export const PeopleSelector: React.FC<PeopleSelectorProps> = ({
    open,
    onClose,
}) => {
    const isFullScreen = useIsMobileWidth();

    return (
        <Dialog
            {...{ open, onClose }}
            fullWidth
            fullScreen={isFullScreen}
            maxWidth={"sm"}
        >
            Hello
        </Dialog>
    );
};
