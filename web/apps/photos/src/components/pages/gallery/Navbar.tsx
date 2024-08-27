import { NavbarBase } from "@/base/components/Navbar";
import { EnteFile } from "@/new/photos/types/file";
import { FlexWrapper, HorizontalFlex } from "@ente/shared/components/Container";
import ArrowBack from "@mui/icons-material/ArrowBack";
import MenuIcon from "@mui/icons-material/Menu";
import { IconButton, Typography } from "@mui/material";
import SearchBar from "components/Search/SearchBar";
import UploadButton from "components/Upload/UploadButton";
import { t } from "i18next";
import { Collection } from "types/collection";
import { UpdateSearch } from "types/search";

interface Iprops {
    openSidebar: () => void;
    isFirstFetch: boolean;
    openUploader: () => void;
    isInSearchMode: boolean;
    isInHiddenSection: boolean;
    setIsInSearchMode: (v: boolean) => void;
    collections: Collection[];
    files: EnteFile[];
    updateSearch: UpdateSearch;
    exitHiddenSection: () => void;
}
export function GalleryNavbar({
    openSidebar,
    openUploader,
    isInSearchMode,
    isInHiddenSection,
    collections,
    files,
    updateSearch,
    setIsInSearchMode,
    exitHiddenSection,
}: Iprops) {
    return (
        <NavbarBase sx={{ background: "transparent", position: "absolute" }}>
            {isInHiddenSection ? (
                <HorizontalFlex
                    gap={"24px"}
                    sx={{
                        width: "100%",
                        background: (theme) => theme.palette.background.default,
                    }}
                >
                    <IconButton onClick={exitHiddenSection}>
                        <ArrowBack />
                    </IconButton>
                    <FlexWrapper>
                        <Typography>{t("HIDDEN")}</Typography>
                    </FlexWrapper>
                </HorizontalFlex>
            ) : (
                <>
                    {!isInSearchMode && (
                        <IconButton onClick={openSidebar}>
                            <MenuIcon />
                        </IconButton>
                    )}
                    <SearchBar
                        isInSearchMode={isInSearchMode}
                        setIsInSearchMode={setIsInSearchMode}
                        collections={collections}
                        files={files}
                        updateSearch={updateSearch}
                    />
                    {!isInSearchMode && (
                        <UploadButton openUploader={openUploader} />
                    )}
                </>
            )}
        </NavbarBase>
    );
}
