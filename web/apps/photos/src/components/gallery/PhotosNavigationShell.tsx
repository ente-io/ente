import { CreateAlbumDialog } from "@/components/collections/CreateAlbumDialog";
import { SearchBar, type SearchBarProps } from "@/components/SearchBar";
import { uploadManager } from "@/services/upload-manager";
import {
    Album02Icon,
    Home01Icon,
    Link05Icon,
    Settings01Icon,
    Upload01Icon,
    UserGroupIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    Box,
    Stack,
    SvgIcon,
    Tooltip,
    useMediaQuery,
    useTheme,
} from "@mui/material";
import { EnteLogo, EnteLogoBox } from "ente-base/components/EnteLogo";
import type { ButtonishProps } from "ente-base/components/mui";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { NavbarBase } from "ente-base/components/Navbar";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { ut } from "ente-base/i18n";
import { thumbnailGridPadding } from "ente-new/photos/components/utils/thumbnail-grid-layout";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { isMLSupported } from "ente-new/photos/services/ml";
import { t } from "i18next";
import { useCallback, useEffect, useState, type ReactNode } from "react";

import type { RemotePullOpts } from ".";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
    type GalleryBarPresentationProps,
} from "./BarImpl";
import type { GalleryBarMode } from "./reducer";

type GalleryNavigation = Omit<
    GalleryBarImplProps,
    | keyof GalleryBarPresentationProps
    | "mode"
    | "onCreateAlbum"
    | "onSelectPerson"
> & { onRemotePull: (opts?: RemotePullOpts) => Promise<void> };

type PhotosNavigationShellProps = SearchBarProps & {
    onSidebar: () => void;
    onUpload: () => void;
    onHome: () => void;
    mode: GalleryBarMode;
    onChangeMode: (mode: GalleryBarMode) => boolean;
};

export const PhotosNavigationShell: React.FC<
    React.PropsWithChildren<
        PhotosNavigationShellProps & {
            alternateHeader: ReactNode;
            galleryNavigation: GalleryNavigation | undefined;
        }
    >
> = ({ alternateHeader, galleryNavigation, children, ...props }) => {
    const [railOpen, setRailOpen] = useState(true);
    const [navigationCollapsed, setNavigationCollapsed] = useState(false);
    const toggleRail = () => setRailOpen((open) => !open);
    const mobile = useMediaQuery(useTheme().breakpoints.down("md"));
    const { show: showMobileNavigation, props: mobileDrawerProps } =
        useModalVisibility();
    const { onClose: closeMobileNavigation } = mobileDrawerProps;
    const { onSelectCollectionID } = galleryNavigation ?? {};
    const { onSelectPerson } = props;
    const selectCollection = useCallback(
        (id: number) => {
            onSelectCollectionID?.(id);
            closeMobileNavigation();
        },
        [onSelectCollectionID, closeMobileNavigation],
    );
    const selectPerson = useCallback(
        (id: string) => {
            onSelectPerson(id);
            closeMobileNavigation();
        },
        [onSelectPerson, closeMobileNavigation],
    );
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } =
        useModalVisibility();
    const [createInHiddenSection, setCreateInHiddenSection] = useState(false);
    const openAlbumCreation = () => {
        setCreateInHiddenSection(props.mode == "hidden-albums");
        showAlbumNameInput();
    };
    useEffect(() => {
        setNavigationCollapsed(false);
    }, [props.mode, props.isInSearchMode]);
    useEffect(() => {
        if (!mobile) closeMobileNavigation();
    }, [mobile, closeMobileNavigation]);
    const handleChangeMode = (mode: GalleryBarMode) => {
        if (mode == "people" && !mobile) {
            closeMobileNavigation();
            props.onChangeMode(mode);
            return;
        }
        const reopeningSection =
            mobile &&
            mode == "albums" &&
            galleryNavigation &&
            !props.isInSearchMode &&
            (props.mode == "hidden-albums" || props.mode == "archive-albums");
        if (
            galleryNavigation &&
            !props.isInSearchMode &&
            ((props.mode == mode &&
                galleryNavigation.activeCollectionID !=
                    PseudoCollectionID.all) ||
                reopeningSection)
        ) {
            if (mobile) {
                if (mobileDrawerProps.open) closeMobileNavigation();
                else showMobileNavigation();
            } else {
                setNavigationCollapsed((collapsed) => !collapsed);
            }
            return;
        }
        if (!props.onChangeMode(mode)) return;
        setNavigationCollapsed(false);
        if (mobile) showMobileNavigation();
    };
    return (
        <Stack
            sx={(theme) => ({
                flex: 1,
                minWidth: 0,
                minHeight: 0,
                bgcolor: "#F4F4F4",
                ...theme.applyStyles("light", {
                    "& > :first-child .MuiButton-colorSecondary, & > :last-child > nav .MuiButton-colorSecondary":
                        { "--mui-palette-secondary-main": "#FFFFFF" },
                }),
                ...theme.applyStyles("dark", { bgcolor: "#161616" }),
            })}
        >
            <NavbarBase
                sx={{
                    pl: { xs: "9px", sm: "16px" },
                    pr: { xs: "12px", sm: "16px" },
                    flexBasis: { xs: "60px", sm: "76px" },
                    borderBottom: "none",
                }}
            >
                {alternateHeader ?? (
                    <NormalHeaderContents
                        onUpload={props.onUpload}
                        {...{ railOpen, toggleRail }}
                    />
                )}
            </NavbarBase>
            <Stack
                direction="row"
                sx={{
                    flex: 1,
                    minWidth: 0,
                    minHeight: 0,
                    p: {
                        xs: railOpen ? "0 8px 8px 0" : "0 8px 8px",
                        sm: railOpen ? "0 11px 11px 0" : "0 11px 11px",
                    },
                }}
            >
                <Box
                    component="nav"
                    sx={{
                        display: railOpen ? "flex" : "none",
                        flexDirection: "column",
                        alignItems: "center",
                        flexShrink: 0,
                        width: { xs: "56px", sm: "72px" },
                        px: { xs: "9px", sm: "14px" },
                        gap: "12px",
                    }}
                >
                    {alternateHeader == null && (
                        <NormalNavigationRail
                            {...props}
                            isHome={
                                props.mode == "albums" &&
                                !props.isInSearchMode &&
                                galleryNavigation?.activeCollectionID ==
                                    PseudoCollectionID.all
                            }
                            onChangeMode={handleChangeMode}
                            opensDialog={mobile}
                            navigationOpen={
                                !!galleryNavigation &&
                                (mobile
                                    ? mobileDrawerProps.open
                                    : !navigationCollapsed)
                            }
                        />
                    )}
                </Box>
                <Stack
                    sx={{
                        flex: 1,
                        minWidth: 0,
                        minHeight: 0,
                        flexDirection: { xs: "column", md: "row" },
                    }}
                >
                    {galleryNavigation && !props.isInSearchMode && (
                        <>
                            <GalleryBarImpl
                                {...galleryNavigation}
                                mode={props.mode}
                                collapsed={!railOpen || navigationCollapsed}
                                mobileDrawerProps={mobileDrawerProps}
                                onCreateAlbum={openAlbumCreation}
                                onSelectCollectionID={selectCollection}
                                onSelectPerson={selectPerson}
                            />
                            <CreateAlbumDialog
                                {...albumNameInputVisibilityProps}
                                isHidden={createInHiddenSection}
                                onRemotePull={galleryNavigation.onRemotePull}
                                onSelectCollectionID={selectCollection}
                            />
                        </>
                    )}
                    <Stack
                        sx={(theme) => ({
                            flex: 1,
                            minWidth: 0,
                            minHeight: 0,
                            pt: { xs: `${thumbnailGridPadding}px`, md: "36px" },
                            px: { xs: 0, md: "12px" },
                            "--mui-palette-background-default": "#FFFFFF",
                            bgcolor: "background.default",
                            borderRadius: "20px",
                            overflow: "hidden",
                            ...theme.applyStyles("dark", {
                                "--mui-palette-background-default": "#212121",
                            }),
                        })}
                    >
                        {children}
                    </Stack>
                </Stack>
            </Stack>
        </Stack>
    );
};

const NormalHeaderContents: React.FC<
    Pick<PhotosNavigationShellProps, "onUpload"> & {
        railOpen: boolean;
        toggleRail: () => void;
    }
> = ({ onUpload, railOpen, toggleRail }) => {
    return (
        <Box
            sx={{
                position: "relative",
                display: "flex",
                alignItems: "center",
                flex: 1,
            }}
        >
            <Tooltip title={railOpen ? ut("Hide sidebar") : ut("Show sidebar")}>
                <FocusVisibleButton
                    color="secondary"
                    aria-label={
                        railOpen ? ut("Hide sidebar") : ut("Show sidebar")
                    }
                    aria-expanded={railOpen}
                    onClick={toggleRail}
                    sx={{
                        minWidth: 0,
                        width: 38,
                        height: 38,
                        p: 0,
                        borderRadius: "12px",
                    }}
                >
                    <SvgIcon
                        sx={{ fontSize: 20, fill: "none" }}
                        stroke="currentColor"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    >
                        <rect x="3" y="4" width="18" height="16" rx="3" />
                        <path
                            d={
                                railOpen
                                    ? "M9 4v16M15 10l-2 2 2 2"
                                    : "M9 4v16M13 10l2 2-2 2"
                            }
                        />
                    </SvgIcon>
                </FocusVisibleButton>
            </Tooltip>
            <EnteLogoBox
                sx={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-50%)",
                    pointerEvents: "none",
                    "& svg": { height: { xs: "18px", sm: "20px" } },
                }}
            >
                <EnteLogo height={15} />
            </EnteLogoBox>
            <Box sx={{ flex: 1 }} />
            <UploadButton onClick={onUpload} />
        </Box>
    );
};

const NormalNavigationRail: React.FC<
    Omit<PhotosNavigationShellProps, "onUpload" | "onChangeMode"> & {
        onChangeMode: (mode: GalleryBarMode) => void;
        isHome: boolean;
        opensDialog: boolean;
        navigationOpen: boolean;
    }
> = ({
    onSidebar,
    onHome,
    mode,
    onChangeMode,
    isHome,
    opensDialog,
    navigationOpen,
    ...props
}) => (
    <>
        <HomeButton onClick={onHome} selected={isHome} />
        <SearchBar {...props} />
        <Box
            aria-hidden
            sx={(theme) => ({
                width: 38,
                height: "2px",
                flexShrink: 0,
                opacity: 0.5,
                bgcolor: "#E0E0E0",
                ...theme.applyStyles("dark", { bgcolor: "#3E3E3E" }),
            })}
        />
        {(["albums", "people", "links"] as const).map((item) =>
            item == "people" && !isMLSupported ? null : (
                <Tooltip key={item} title={t(item)}>
                    <FocusVisibleButton
                        color="secondary"
                        aria-label={t(item)}
                        aria-pressed={
                            navigationOpen &&
                            !isHome &&
                            !props.isInSearchMode &&
                            (mode == item ||
                                (item == "albums" &&
                                    (mode == "hidden-albums" ||
                                        mode == "archive-albums")))
                        }
                        aria-haspopup={opensDialog ? "dialog" : undefined}
                        onClick={() => onChangeMode(item)}
                        sx={{
                            minWidth: 0,
                            width: 38,
                            height: 38,
                            flexShrink: 0,
                            p: 0,
                            borderRadius: "12px",
                            color: "text.base",
                            '&[aria-pressed="true"]': {
                                color: "#FFFFFF",
                                bgcolor: "accent.main",
                                "&:hover": { bgcolor: "accent.main" },
                            },
                        }}
                    >
                        <HugeiconsIcon
                            icon={
                                item == "albums"
                                    ? Album02Icon
                                    : item == "links"
                                      ? Link05Icon
                                      : UserGroupIcon
                            }
                            size={20}
                            strokeWidth={1.8}
                        />
                    </FocusVisibleButton>
                </Tooltip>
            ),
        )}
        <Box sx={{ flex: 1 }} />
        <Tooltip title={t("settings")}>
            <FocusVisibleButton
                color="secondary"
                aria-label={t("settings")}
                aria-haspopup="dialog"
                onClick={onSidebar}
                sx={{
                    minWidth: 0,
                    width: 38,
                    height: 38,
                    flexShrink: 0,
                    mb: "13px",
                    p: 0,
                    borderRadius: "12px",
                }}
            >
                <HugeiconsIcon
                    icon={Settings01Icon}
                    size={20}
                    strokeWidth={1.8}
                />
            </FocusVisibleButton>
        </Tooltip>
    </>
);

const HomeButton: React.FC<ButtonishProps & { selected: boolean }> = ({
    onClick,
    selected,
}) => (
    <Tooltip title={ut("Home")}>
        <FocusVisibleButton
            color="secondary"
            aria-label={ut("Home")}
            aria-pressed={selected}
            onClick={onClick}
            sx={{
                minWidth: 0,
                width: 38,
                height: 38,
                p: 0,
                borderRadius: "12px",
                color: "text.base",
                '&[aria-pressed="true"]': {
                    color: "#FFFFFF",
                    bgcolor: "accent.main",
                    "&:hover": { bgcolor: "accent.main" },
                },
            }}
        >
            <HugeiconsIcon icon={Home01Icon} size={20} strokeWidth={1.8} />
        </FocusVisibleButton>
    </Tooltip>
);

const UploadButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = uploadManager.isUploadInProgress();
    const isSmallWidth = useIsSmallWidth();

    const icon = (
        <HugeiconsIcon icon={Upload01Icon} size={20} strokeWidth={1.8} />
    );

    return (
        <>
            {isSmallWidth ? (
                <FocusVisibleButton
                    color="secondary"
                    aria-label={t("upload")}
                    sx={{
                        minWidth: 0,
                        width: 38,
                        height: 38,
                        p: 0,
                        borderRadius: "12px",
                    }}
                    {...{ onClick, disabled }}
                >
                    {icon}
                </FocusVisibleButton>
            ) : (
                <FocusVisibleButton
                    color="secondary"
                    startIcon={icon}
                    sx={{
                        minWidth: "140px",
                        flexShrink: 0,
                        whiteSpace: "nowrap",
                        height: "52px",
                        p: "18px 24px",
                        borderRadius: "20px",
                        border: 0,
                        fontSize: "14px",
                        fontWeight: 600,
                        lineHeight: "20px",
                        gap: "8px",
                        "& .MuiButton-startIcon": { m: 0 },
                    }}
                    {...{ onClick, disabled }}
                >
                    {t("upload")}
                </FocusVisibleButton>
            )}
        </>
    );
};
