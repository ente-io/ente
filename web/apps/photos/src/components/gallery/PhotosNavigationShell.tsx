import { SearchBar, type SearchBarProps } from "@/components/SearchBar";
import { uploadManager } from "@/services/upload-manager";
import { Upload01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import HomeIcon from "@mui/icons-material/HomeOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import SettingsIcon from "@mui/icons-material/SettingsOutlined";
import { Box, IconButton, Stack, Tooltip } from "@mui/material";
import { EnteLogo, EnteLogoBox } from "ente-base/components/EnteLogo";
import type { ButtonishProps } from "ente-base/components/mui";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { NavbarBase } from "ente-base/components/Navbar";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { ut } from "ente-base/i18n";
import { t } from "i18next";
import type { ReactNode } from "react";

type PhotosNavigationShellProps = SearchBarProps & {
    onSidebar: () => void;
    onUpload: () => void;
    onHome: () => void;
};

export const PhotosNavigationShell: React.FC<
    React.PropsWithChildren<
        PhotosNavigationShellProps & {
            showRail: boolean;
            showNormalNavigation: boolean;
            hasSelection: boolean;
            alternateHeader: ReactNode;
        }
    >
> = ({
    showRail,
    showNormalNavigation,
    hasSelection,
    alternateHeader,
    children,
    ...props
}) => {
    const isSmallWidth = useIsSmallWidth();
    return (
        <Stack
            sx={(theme) => ({
                flex: 1,
                minWidth: 0,
                minHeight: 0,
                ...(showRail && {
                    [theme.breakpoints.up("sm")]: {
                        bgcolor: "#F4F4F4",
                        ...theme.applyStyles("light", {
                            "& > :first-child .MuiButton-colorSecondary, & > :last-child > nav .MuiButton-colorSecondary":
                                { "--mui-palette-secondary-main": "#FFFFFF" },
                        }),
                        ...theme.applyStyles("dark", { bgcolor: "#161616" }),
                    },
                }),
            })}
        >
            {showRail && (
                <NavbarBase
                    sx={[
                        {
                            mb: { xs: "12px", sm: 0 },
                            px: { xs: "4px", sm: "16px" },
                            borderBottom: { sm: "none" },
                        },
                        hasSelection && { borderColor: "accent.main" },
                    ]}
                >
                    {showNormalNavigation ? (
                        <NormalHeaderContents {...props} />
                    ) : (
                        alternateHeader
                    )}
                </NavbarBase>
            )}
            <Stack direction="row" sx={{ flex: 1, minWidth: 0, minHeight: 0 }}>
                {showRail && (
                    <Box
                        component="nav"
                        sx={{
                            display: { xs: "none", sm: "flex" },
                            flexDirection: "column",
                            alignItems: "center",
                            flexShrink: 0,
                            width: "72px",
                            py: "12px",
                            gap: "12px",
                        }}
                    >
                        {!isSmallWidth && showNormalNavigation && (
                            <NormalNavigationRail {...props} />
                        )}
                    </Box>
                )}
                <Stack
                    sx={(theme) => ({
                        flex: 1,
                        minWidth: 0,
                        minHeight: 0,
                        pt: showRail ? { xs: 0, sm: "12px" } : 0,
                        ...(showRail && {
                            [theme.breakpoints.up("sm")]: {
                                "--mui-palette-background-default": "#FFFFFF",
                                bgcolor: "background.default",
                                ...theme.applyStyles("dark", {
                                    "--mui-palette-background-default":
                                        "#212121",
                                }),
                            },
                        }),
                    })}
                >
                    {children}
                </Stack>
            </Stack>
        </Stack>
    );
};

const NormalHeaderContents: React.FC<PhotosNavigationShellProps> = ({
    onSidebar,
    onUpload,
    onHome,
    ...props
}) => {
    const isSmallWidth = useIsSmallWidth();

    return (
        <Box
            sx={{
                position: "relative",
                display: "flex",
                alignItems: "center",
                flex: 1,
            }}
        >
            {isSmallWidth && <SidebarButton onClick={onSidebar} />}
            {!isSmallWidth && (
                <Tooltip title={ut("Home")}>
                    <FocusVisibleButton
                        color="secondary"
                        aria-label={ut("Home")}
                        onClick={onHome}
                        sx={{
                            minWidth: 0,
                            width: 40,
                            height: 40,
                            p: 0,
                            borderRadius: "12px",
                        }}
                    >
                        <HomeIcon sx={{ fontSize: 20 }} />
                    </FocusVisibleButton>
                </Tooltip>
            )}
            <EnteLogoBox
                sx={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-50%)",
                    pointerEvents: "none",
                    "& svg": { height: { xs: "15px", sm: "20px" } },
                }}
            >
                <EnteLogo height={15} />
            </EnteLogoBox>
            <Box sx={{ flex: 1 }} />
            {isSmallWidth && <SearchBar {...props} />}
            <UploadButton onClick={onUpload} />
        </Box>
    );
};

const NormalNavigationRail: React.FC<
    SearchBarProps & { onSidebar: () => void }
> = ({ onSidebar, ...props }) => (
    <>
        <SearchBar {...props} placement="rail" />
        <Box sx={{ flex: 1 }} />
        <Tooltip title={t("settings")}>
            <FocusVisibleButton
                color="secondary"
                aria-label={t("settings")}
                aria-haspopup="dialog"
                onClick={onSidebar}
                sx={{
                    minWidth: 0,
                    width: 40,
                    height: 40,
                    flexShrink: 0,
                    p: 0,
                    borderRadius: "12px",
                }}
            >
                <SettingsIcon sx={{ fontSize: 20 }} />
            </FocusVisibleButton>
        </Tooltip>
    </>
);

const SidebarButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <IconButton {...{ onClick }}>
        <MenuIcon />
    </IconButton>
);

export const UploadButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = uploadManager.isUploadInProgress();
    const isSmallWidth = useIsSmallWidth();

    const icon = <HugeiconsIcon icon={Upload01Icon} size={20} />;

    return (
        <>
            {isSmallWidth ? (
                <IconButton {...{ onClick, disabled }}>{icon}</IconButton>
            ) : (
                <FocusVisibleButton
                    color="secondary"
                    startIcon={icon}
                    sx={{ borderRadius: "16px" }}
                    {...{ onClick, disabled }}
                >
                    {t("upload")}
                </FocusVisibleButton>
            )}
        </>
    );
};
