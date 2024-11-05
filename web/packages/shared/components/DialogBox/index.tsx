import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    Breakpoint,
    DialogActions,
    DialogContent,
    DialogProps,
    Typography,
    type ButtonBaseActions,
} from "@mui/material";
import { t } from "i18next";
import React, { useRef } from "react";
import DialogIcon from "./DialogIcon";
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from "./TitleWithCloseButton";
import DialogBoxBase from "./base";
import { DialogBoxAttributes } from "./types";

type IProps = React.PropsWithChildren<
    Omit<DialogProps, "onClose" | "maxSize"> & {
        onClose: () => void;
        attributes: DialogBoxAttributes;
        size?: Breakpoint;
        titleCloseButton?: boolean;
    }
>;

export default function DialogBox({
    attributes,
    children,
    open,
    size,
    onClose,
    titleCloseButton,
    ...props
}: IProps) {
    // Sometimes we wish to autoFocus on the primary action button in the dialog
    // (e.g. in the delete confirmation) so that the user can use their keyboard
    // to quickly select it.
    //
    // To allow this, MUI buttons provide an `autoFocus` prop. However, while
    // the button does get auto focused, it doesn't show the visual
    // focus-visible state until the user does an keyboard action.
    //
    // Below is the current best workaround to get the focused button to also
    // show the focus-visible state. It uses the onEnter callback of the
    // transition to focus on the ref to the auto focused button (if any).
    //
    // https://github.com/mui/material-ui/issues/8438
    const proceedButtonRef = useRef<ButtonBaseActions | null>(null);

    if (!attributes) {
        return <></>;
    }

    const handleClose = dialogCloseHandler({
        staticBackdrop: attributes.staticBackdrop,
        nonClosable: attributes.nonClosable,
        onClose: onClose,
    });

    const handleDialogEnter = () => {
        if (attributes.proceed?.autoFocus)
            proceedButtonRef?.current.focusVisible();
    };

    return (
        <DialogBoxBase
            open={open}
            maxWidth={size}
            onClose={handleClose}
            TransitionProps={{ onEnter: handleDialogEnter }}
            {...props}
        >
            {attributes.icon && <DialogIcon icon={attributes.icon} />}
            {attributes.title && (
                <DialogTitleWithCloseButton
                    onClose={
                        titleCloseButton && !attributes.nonClosable && onClose
                    }
                >
                    {attributes.title}
                </DialogTitleWithCloseButton>
            )}
            {(children || attributes?.content) && (
                <DialogContent>
                    {children || (
                        <Typography color="text.muted">
                            {attributes.content}
                        </Typography>
                    )}
                </DialogContent>
            )}
            {(attributes.close || attributes.proceed) && (
                <DialogActions>
                    <>
                        {attributes.close && (
                            <FocusVisibleButton
                                size="large"
                                color={attributes.close?.variant ?? "secondary"}
                                onClick={() => {
                                    attributes.close.action &&
                                        attributes.close?.action();
                                    onClose();
                                }}
                            >
                                {attributes.close?.text ?? t("ok")}
                            </FocusVisibleButton>
                        )}
                        {attributes.proceed && (
                            <FocusVisibleButton
                                action={proceedButtonRef}
                                size="large"
                                color={attributes.proceed?.variant}
                                onClick={() => {
                                    attributes.proceed.action();
                                    onClose();
                                }}
                                disabled={attributes.proceed.disabled}
                                autoFocus={attributes.proceed?.autoFocus}
                            >
                                {attributes.proceed.text}
                            </FocusVisibleButton>
                        )}
                        {attributes.secondary && (
                            <FocusVisibleButton
                                size="large"
                                color={attributes.secondary?.variant}
                                onClick={() => {
                                    attributes.secondary.action();
                                    onClose();
                                }}
                                disabled={attributes.secondary.disabled}
                            >
                                {attributes.secondary.text}
                            </FocusVisibleButton>
                        )}
                    </>
                </DialogActions>
            )}
        </DialogBoxBase>
    );
}
