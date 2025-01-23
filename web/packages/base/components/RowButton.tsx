import { EnteSwitch } from "@/base/components/EnteSwitch";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    Box,
    Divider,
    Stack,
    styled,
    Typography,
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
 */

export const RowButtonGroup = styled("div")(
    ({ theme }) => `
    // & > .MuiMenuItem-root{
    //     border-radius: 8px;
    //     background-color: transparent;
    // }
    // & > .MuiMenuItem-root:not(:last-of-type) {
    //     border-bottom-left-radius: 0;
    //     border-bottom-right-radius: 0;
    // }
    // & > .MuiMenuItem-root:not(:first-of-type) {
    //     border-top-left-radius: 0;
    //     border-top-right-radius: 0;
    // }
    // background-color: ${theme.vars.palette.fill.faint};
    // border-radius: 8px;
`,
);

interface RowButtonProps {
    /**
     * Variants:
     *
     * - "primary" (default): A menu item with a filled in background color.
     *
     * - "captioned": A variant of primary with an associated {@link caption})
     *   shown alongside the main {@link label}, separated from it by a bullet.
     *
     * - "toggle": A variant of primary that shows a toggle button (an
     *   {@link EnteSwitch}) at the trailing edge of the menu item.
     *
     * - "secondary": A menu item without a fill.
     *
     * - "mini": A variant of secondary with a smaller font.
     */
    variant?: "primary" | "captioned" | "toggle" | "secondary";
    /**
     * Color of the menu item.
     *
     * Semantically, this is similar to the "color" props for a MUI button,
     * except we only support two cases for this menu item component:
     *
     * - "primary" (default): A menu item that uses "text.base" as the color of
     *   the text (and an approprite background color, if needed, based on the
     *   value of the "variant").
     *
     * - "critical": A menu item that uses "critical.main" as the color of the
     *   text. The background fill, if any, will be the same as color "primary".
     */
    color?: "primary" | "critical";
    fontWeight?: TypographyProps["fontWeight"];
    /**
     * Called when the menu item, or the switch it contains, is clicked.
     *
     * - For menu items with variant "toggle", this will be called if the user
     *   toggles the value of the {@link EnteSwitch}.
     *
     * - For all other variants, this will be called when the user activates
     *   (e.g. clicks) the menu item itself.
     */
    onClick: () => void;
    /**
     * The state of the toggle associated with the menu item.
     *
     * Only valid for menu items with variant "toggle".
     */
    checked?: boolean;
    /**
     * Optional icon shown at the leading edge of the menu item.
     *
     * This is usually an icon like an {@link SvgIcon}, but it can be any
     * arbitrary component, the menu item does not make any assumptions as to
     * what this is.
     *
     * If it is an {@link SvgIcon}, the menu item will size it appropriately.
     */
    startIcon?: React.ReactNode;
    /**
     * Optional icon shown at the trailing edge of the menu item.
     *
     * Similar to {@link startIcon} this can be any arbitrary component, though
     * usually it is an {@link SvgIcon} whose size the menu item will set.
     *
     * Not used if variant is "toggle".
     */
    endIcon?: React.ReactNode;
    /**
     * The label for the component.
     *
     * Usually this is expected to be a string, in which case it is wrapped up
     * in an appropriate {@link Typography} and shown on the menu item. But it
     * can be an arbitrary react component too, to allow customizing its
     * appearance or otherwise modifying it in one off cases (it will be used as
     * it is and not wrapped in a {@link Typography} if it is not a string).
     */
    label: React.ReactNode;
    /**
     * The text (or icon) to show alongside the {@link label} when the variant
     * is "captioned".
     *
     * This is usually expected to be a string, in which case it is wrapped in a
     * {@link Typography} component before being rendered. However, it can also
     * be an {@link SvgIcon} (or any an arbitrary component), though in terms of
     * styling, only an {@link SvgIcon} usually makes sense.
     *
     * Similar to {@link label}, it will not be wrapped in a  {@link Typography}
     * if it is not a string.
     */
    caption?: React.ReactNode;
    /**
     * If true, then the menu item will be disabled.
     */
    disabled?: boolean;
}

/**
 * A button that looks like a row in a group of options / choices.
 *
 * It can be used both standalone, or as part of a {@link RowButtonGroup}.
 */
export const RowButton2 = (
    { variant }, // `backgroundColor: 'tomato', color: 'white'`
) => (
    <RowButtonRoot variant={variant} color="primary">
        Submit
    </RowButtonRoot>
);
export const RowButton: React.FC<RowButtonProps> = ({
    variant = "primary",
    color = "primary",
    fontWeight = "medium",
    onClick,
    checked,
    startIcon,
    endIcon,
    label,
    caption,
    disabled = false,
}) => (
    <RowButtonRoot
        variant={variant}
        fullWidth
        disabled={disabled}
        onClick={() => {
            if (variant != "toggle") onClick();
        }}
        // disableRipple={variant == "toggle"}
        // sx={[
        //     {
        //         // Remove button's default padding.
        //         p: 0,
        //     },
        // ]}
        // sx={[
        //     {
        //         p: 0,
        //         borderRadius: "4px",
        //         color: color == "critical" ? "critical.main" : "text.base",
        //         "& .MuiSvgIcon-root": {
        //             fontSize: "20px",
        //         },
        //     },
        //     variant == "secondary" &&
        //         ((theme) => ({
        //             "&:hover": {
        //                 backgroundColor: theme.vars.palette.fill.faintHover,
        //             },
        //         })),
        //     variant != "secondary" &&
        //         ((theme) => ({
        //             backgroundColor: theme.vars.palette.fill.faint,
        //             "&:hover": {
        //                 backgroundColor:
        //                     // Lighter fill for critical variant to retain
        //                     // legibility of the red text.
        //                     color == "critical"
        //                         ? theme.vars.palette.fill.faintHover
        //                         : theme.vars.palette.fill.muted,
        //             },
        //         })),
        // ]}
    >
        <Stack
            direction="row"
            sx={{
                flex: 1,
                justifyContent: "space-between",
                alignItems: "center",
                px: "16px",
                pr: "12px",
            }}
        >
            <Stack direction="row" sx={{ py: "14px", gap: "10px" }}>
                {startIcon && startIcon}
                <Box px={"2px"}>
                    {typeof label !== "string" ? (
                        label
                    ) : variant == "captioned" ? (
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

type RowButtonRootProps = Pick<RowButtonProps, "variant">;

const Button2 = styled(FocusVisibleButton)(({ theme }) => ({
    border: "none",
    padding: "0.75rem",
    // ...other base styles
    variants: [
        {
            props: { variant: "captioned", color: "primary" },
            style: {
                backgroundColor: theme.vars.palette.accent.main,
                color: "white",
            },
        },
        {
            props: { variant: "secondary", color: "primary" },
            style: { backgroundColor: "tomato", color: "white" },
        },
    ],
}));

const RowButtonRoot = styled(FocusVisibleButton, {
    // shouldForwardProp: (prop) => prop === "classes",
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
            props: { variant: "primary" },
            style: { backgroundColor: theme.vars.palette.fill.faint },
        },
        {
            props: { variant: "toggle" },
            style: { backgroundColor: theme.vars.palette.fill.faint },
        },
        {
            props: { variant: "captioned" },
            style: { backgroundColor: theme.vars.palette.fill.faint },
        },
        {
            props: { variant: "secondary" },
            style: { backgroundColor: "transparent", color: "white" },
        },
    ],

    // variants: [
    //     {
    //         props: { variant: "secondary" },
    //         style: {
    //             backgroundColor: "red",
    //         },
    //     },
    // ],
    // ...theme.typography.body1,
    // display: "flex",
    // justifyContent: "flex-start",
    // alignItems: "center",
    // position: "relative",
    // textDecoration: "none",
    // minHeight: 48,
    // paddingTop: 6,
    // paddingBottom: 6,
    // boxSizing: "border-box",
    // whiteSpace: "nowrap",
    // "&:hover": {
    //     textDecoration: "none",
    //     backgroundColor: theme.vars.palette.action.hover,
    //     // Reset on touch devices, it doesn't add specificity
    //     "@media (hover: none)": {
    //         backgroundColor: "transparent",
    //     },
    // },
    // [`&.${menuItemClasses.selected}`]: {
    //     backgroundColor: theme.vars
    //         ? `rgba(${theme.vars.palette.primary.mainChannel} / ${theme.vars.palette.action.selectedOpacity})`
    //         : alpha(
    //               theme.palette.primary.main,
    //               theme.palette.action.selectedOpacity,
    //           ),
    //     [`&.${menuItemClasses.focusVisible}`]: {
    //         backgroundColor: theme.vars
    //             ? `rgba(${theme.vars.palette.primary.mainChannel} / calc(${theme.vars.palette.action.selectedOpacity} + ${theme.vars.palette.action.focusOpacity}))`
    //             : alpha(
    //                   theme.palette.primary.main,
    //                   theme.palette.action.selectedOpacity +
    //                       theme.palette.action.focusOpacity,
    //               ),
    //     },
    // },
    // [`&.${menuItemClasses.selected}:hover`]: {
    //     backgroundColor: theme.vars
    //         ? `rgba(${theme.vars.palette.primary.mainChannel} / calc(${theme.vars.palette.action.selectedOpacity} + ${theme.vars.palette.action.hoverOpacity}))`
    //         : alpha(
    //               theme.palette.primary.main,
    //               theme.palette.action.selectedOpacity +
    //                   theme.palette.action.hoverOpacity,
    //           ),
    //     // Reset on touch devices, it doesn't add specificity
    //     "@media (hover: none)": {
    //         backgroundColor: theme.vars
    //             ? `rgba(${theme.vars.palette.primary.mainChannel} / ${theme.vars.palette.action.selectedOpacity})`
    //             : alpha(
    //                   theme.palette.primary.main,
    //                   theme.palette.action.selectedOpacity,
    //               ),
    //     },
    // },
    // TODO:
    // [`&.${menuItemClasses.focusVisible}`]: {
    //     backgroundColor: theme.vars.palette.action.focus,
    // },
    // [`&.${menuItemClasses.disabled}`]: {
    //     opacity: theme.vars.palette.action.disabledOpacity,
    // },
    // [`& .${listItemTextClasses.root}`]: {
    //     marginTop: 0,
    //     marginBottom: 0,
    // },
    // [`& .${listItemTextClasses.inset}`]: {
    //     paddingLeft: 36,
    // },
    // [`& .${listItemIconClasses.root}`]: {
    //     minWidth: 36,
    // },
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
