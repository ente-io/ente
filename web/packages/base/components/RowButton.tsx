import { EnteSwitch } from "@/base/components/EnteSwitch";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    Box,
    Divider,
    Stack,
    styled,
    Typography,
    type ButtonProps,
    type TypographyProps,
} from "@mui/material";
import React from "react";

interface RowButtonGroupTitleProps {
    /**
     * An optional leading SvgIcon before the title.
     */
    icon?: React.ReactNode;
}

/**
 * A section title, meant to precede a {@link RowButtonGroup}.
 */
export const RowButtonGroupTitle: React.FC<
    React.PropsWithChildren<RowButtonGroupTitleProps>
> = ({ children, icon }) => (
    <Stack
        direction="row"
        sx={{
            px: "8px",
            py: "6px",
            gap: "8px",
            "& > svg": {
                fontSize: "17px",
                color: "stroke.muted",
            },
        }}
    >
        {icon && icon}
        <Typography variant="small" sx={{ color: "text.muted" }}>
            {children}
        </Typography>
    </Stack>
);

/**
 * A short description text meant to come after a {@link RowButtonGroup}.
 */
export const RowButtonGroupHint: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Typography
        variant="small"
        sx={{ color: "text.muted", px: "8px", py: "6px" }}
    >
        {children}
    </Typography>
);

interface RowButtonDividerProps {
    /**
     * If true, then the divider leaves the leading edge hanging which visually
     * looks better when used to separate buttons which have leading icons.
     */
    hasIcon?: boolean;
}

/**
 * A divider for buttons in a {@link RowButtonGroup}.
 */
export const RowButtonDivider: React.FC<RowButtonDividerProps> = ({
    hasIcon,
}) => (
    <Divider
        sx={[{ "&&&": { my: 0 } }, hasIcon ? { ml: "48px" } : { ml: "16px" }]}
    />
);

/**
 * A group of {@link RowButton}s that visually look together as a single
 * section.
 *
 * {@link RowButtonGroupTitle} can be used to provide a title for the entire
 * group, and {@link RowButtonGroupHint} can be used to provide a hint text that
 * follows the group.
 *
 * {@link RowButtonDivider} can be used to to separate the individual buttons in
 * the group.
 *
 * ---
 *
 * Note: {@link RowButtonGroup} is not designed to work with the "secondary"
 * variant of {@link RowButton}.
 */
export const RowButtonGroup = styled("div")(
    ({ theme }) => `
    background-color: ${theme.vars.palette.fill.faint};
    border-radius: 8px;
    /** Modify the RowButton style when it is placed inside a RowButtonGroup */
    & > button {
        border-radius: 8px;
        background-color: transparent;
    }
    & > button:not(:last-of-type) {
        border-bottom-left-radius: 0;
        border-bottom-right-radius: 0;
    }
    & > button:not(:first-of-type) {
        border-top-left-radius: 0;
        border-top-right-radius: 0;
    }
    & > button:hover {
        /* These fills are translucent and additive, and the RowButtonGroup
           already has a background, so pick a (transparent) color that gives us
           a similar outcome of the hover state as for a RowButton that is not
           inside a RowButtonGroup */
        background-color: ${theme.vars.palette.fill.faintHover};
    }
`,
);

interface RowButtonProps {
    /**
     * Variants:
     *
     * - "primary" (default): A row button with a filled in background color.
     *
     * - "toggle": A variant of primary that shows a toggle button (an
     *   {@link EnteSwitch}) at the trailing edge of the row button.
     *
     * - "secondary": A row button without a fill.
     */
    variant?: "primary" | "toggle" | "secondary";
    /**
     * Color of the row button.
     *
     * Semantically, this is similar to the "color" props for a MUI button,
     * except we only support two cases for this row button component:
     *
     * - "primary" (default): A row button that uses "text.base" as the color of
     *   the text (and an approprite background color, if needed, based on the
     *   value of the {@link variant}).
     *
     * - "critical": A row button that uses "critical.main" as the color of the
     *   text. The background fill, if any, will be the same as what "primary"
     *   would've entailed.
     */
    color?: "primary" | "critical";
    fontWeight?: TypographyProps["fontWeight"];
    /**
     * If true, then the row button will be disabled.
     */
    disabled?: boolean;
    /**
     * Called when the row button, or the switch it contains, is clicked.
     *
     * - For row buttons with variant "toggle", this will be called if the user
     *   toggles the value of the {@link EnteSwitch}.
     *
     * - For all other variants, this will be called when the user activates
     *   (e.g. clicks) the row button itself.
     */
    onClick: () => void;
    /**
     * The state of the toggle associated with the row button.
     *
     * Only valid for row buttons with variant "toggle".
     */
    checked?: boolean;
    /**
     * Optional icon shown at the leading edge of the row button.
     *
     * This is usually an icon like an {@link SvgIcon}, but it can be any
     * arbitrary component, the row button does not make any assumptions as to
     * what this is.
     *
     * If it is an {@link SvgIcon}, the row button will size it appropriately.
     */
    startIcon?: React.ReactNode;
    /**
     * Optional icon shown at the trailing edge of the row button.
     *
     * Similar to {@link startIcon} this can be any arbitrary component, though
     * usually it is an {@link SvgIcon} whose size the row button will set.
     *
     * Not used if variant is "toggle".
     */
    endIcon?: React.ReactNode;
    /**
     * The label for the component.
     *
     * Usually this is expected to be a string, in which case it is wrapped up
     * in an appropriate {@link Typography} and shown on the row button. But it
     * can be an arbitrary react component too, to allow customizing its
     * appearance or otherwise modifying it in one off cases (it will be used as
     * it is and not wrapped in a {@link Typography} if it is not a string).
     */
    label: React.ReactNode;
    /**
     * The text (or icon) to show alongside {@link label}, separated from it by
     * a bullet.
     *
     * This is usually expected to be a string, in which case it is wrapped in a
     * {@link Typography} component and styled with a muted text color before
     * being rendered.
     *
     * However, it can also be an {@link SvgIcon} (or any an arbitrary
     * component), though in terms of styling, only an {@link SvgIcon} usually
     * makes sense.
     *
     * Similar to {@link label}, it will not be wrapped in a {@link Typography}
     * if it is not a string.
     */
    caption?: React.ReactNode;
}

/**
 * A button that looks like a row in a group of options / choices.
 *
 * It can be used both standalone, or as part of a {@link RowButtonGroup}.
 */
export const RowButton: React.FC<RowButtonProps> = ({
    variant = "primary",
    color = "primary",
    fontWeight = "medium",
    disabled = false,
    checked,
    startIcon,
    endIcon,
    label,
    caption,
    onClick,
}) => (
    <RowButtonRoot
        rbVariant={variant}
        fullWidth
        disabled={disabled}
        onClick={() => {
            if (variant != "toggle") onClick();
        }}
    >
        <Stack
            direction="row"
            sx={[
                {
                    flex: 1,
                    justifyContent: "space-between",
                    alignItems: "center",
                    px: "16px",
                    pr: "12px",
                    color: "primary.main",
                },
                color == "critical" && { color: "critical.main" },
            ]}
        >
            <Stack direction="row" sx={{ py: "14px", gap: "10px" }}>
                {startIcon && startIcon}
                <Box px={"2px"}>
                    {typeof label !== "string" ? (
                        label
                    ) : caption ? (
                        <Stack
                            direction="row"
                            sx={{ gap: "4px", alignItems: "center" }}
                        >
                            <Typography>{label}</Typography>
                            <CaptionTypography color={color}>
                                {"•"}
                            </CaptionTypography>
                            <CaptionTypography color={color}>
                                {caption}
                            </CaptionTypography>
                        </Stack>
                    ) : (
                        <Typography fontWeight={fontWeight}>{label}</Typography>
                    )}
                </Box>
            </Stack>
            {endIcon ? (
                endIcon
            ) : variant == "toggle" ? (
                <EnteSwitch {...{ checked, onClick }} />
            ) : null}
        </Stack>
    </RowButtonRoot>
);

type RowButtonRootProps = ButtonProps & {
    // Prefix with "rb" to differentiate this from the "variant" prop of the MUI
    // button that we're styling.
    rbVariant: RowButtonProps["variant"];
};

const RowButtonRoot = styled(FocusVisibleButton, {
    shouldForwardProp: (prop) => prop != "rbVariant",
    // name: "MuiMenuItem",
})<React.PropsWithChildren<RowButtonRootProps>>(({ theme }) => ({
    // Remove button's default padding.
    padding: 0,
    // Set the size of the any icons (SvgIcon instances) provided to us to make
    // them fit with the Typography within the button's content.
    "& .MuiSvgIcon-root": {
        fontSize: "20px",
    },
    variants: [
        {
            props: { rbVariant: "primary" },
            style: {
                backgroundColor: theme.vars.palette.fill.faint,
                "&:hover": {
                    backgroundColor: theme.vars.palette.fill.muted,
                },
            },
        },
        {
            props: { rbVariant: "toggle" },
            style: { backgroundColor: theme.vars.palette.fill.faint },
        },
        {
            props: { rbVariant: "secondary" },
            style: {
                backgroundColor: "transparent",
                color: "white",
                "&:hover": { backgroundColor: theme.vars.palette.fill.faint },
            },
        },
    ],
}));

const CaptionTypography: React.FC<
    React.PropsWithChildren<{ color: RowButtonProps["color"] }>
> = ({ color, children }) => (
    <Typography
        variant="small"
        sx={[
            color == "critical"
                ? { color: "critical.main" }
                : { color: "text.faint" },
        ]}
    >
        {children}
    </Typography>
);
