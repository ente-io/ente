import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import log from "@/base/log";
import { wipClusterPageContents } from "@/new/photos/services/ml";
import { EnteFile } from "@/new/photos/types/file";
import {
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { CustomError } from "@ente/shared/error";
import useMemoSingleThreaded from "@ente/shared/hooks/useMemoSingleThreaded";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import { Box, IconButton, styled } from "@mui/material";
import Typography from "@mui/material/Typography";
import { DedupePhotoList } from "components/PhotoList/dedupe";
import PreviewCard from "components/pages/gallery/PreviewCard";
import { ALL_SECTION } from "constants/collection";
import { t } from "i18next";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { createContext, useContext, useEffect, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { getLocalCollections } from "services/collectionService";
import { Duplicate } from "services/deduplicationService";
import {
    DeduplicateContextType,
    DefaultDeduplicateContext,
} from "types/deduplicate";
import { updateFileMsrcProps } from "utils/photoFrame";

const DeduplicateContext = createContext<DeduplicateContextType>(
    DefaultDeduplicateContext,
);

const Info = styled("div")`
    padding: 24px;
    font-size: 18px;
`;

// TODO-Cluster Temporary component for debugging
export default function Deduplicate() {
    const { startLoading, finishLoading, showNavBar } = useContext(AppContext);
    const [duplicates, setDuplicates] = useState<Duplicate[]>(null);
    const [collectionNameMap, setCollectionNameMap] = useState(
        new Map<number, string>(),
    );

    useEffect(() => {
        showNavBar(true);
    }, []);

    useEffect(() => {
        syncWithRemote();
    }, []);

    const syncWithRemote = async () => {
        startLoading();
        const collections = await getLocalCollections();
        const collectionNameMap = new Map<number, string>();
        for (const collection of collections) {
            collectionNameMap.set(collection.id, collection.name);
        }
        setCollectionNameMap(collectionNameMap);
        const faceAndFiles = await wipClusterPageContents();
        // const files = await getLocalFiles();
        // const duplicateFiles = await getDuplicates(files, collectionNameMap);
        const duplicateFiles = faceAndFiles.map(({ face, file }) => ({
            files: [file],
            size: face.score,
        }));
        const currFileSizeMap = new Map<number, number>();
        let toSelectFileIDs: number[] = [];
        let count = 0;
        for (const dupe of duplicateFiles) {
            // select all except first file
            toSelectFileIDs = [
                ...toSelectFileIDs,
                ...dupe.files.slice(1).map((f) => f.id),
            ];
            count += dupe.files.length - 1;

            for (const file of dupe.files) {
                currFileSizeMap.set(file.id, dupe.size);
            }
        }
        setDuplicates(duplicateFiles);
        const selectedFiles = {
            count: count,
            ownCount: count,
            collectionID: ALL_SECTION,
        };
        for (const fileID of toSelectFileIDs) {
            selectedFiles[fileID] = true;
        }

        finishLoading();
    };

    const duplicateFiles = useMemoSingleThreaded(() => {
        return (duplicates ?? []).reduce((acc, dupe) => {
            return [...acc, ...dupe.files];
        }, []);
    }, [duplicates]);

    if (!duplicates) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    return (
        <DeduplicateContext.Provider
            value={{
                ...DefaultDeduplicateContext,
                collectionNameMap,
                isOnDeduplicatePage: true,
            }}
        >
            {duplicateFiles.length > 0 && (
                <Info>{t("DEDUPLICATE_BASED_ON_SIZE")}</Info>
            )}
            {duplicateFiles.length === 0 ? (
                <VerticallyCentered>
                    <Typography variant="large" color="text.muted">
                        {t("NO_DUPLICATES_FOUND")}
                    </Typography>
                </VerticallyCentered>
            ) : (
                <ClusterDebugPhotoFrame
                    files={duplicateFiles}
                    duplicates={duplicates}
                    activeCollectionID={ALL_SECTION}
                />
            )}
            <Options />
        </DeduplicateContext.Provider>
    );
}

const Options: React.FC = () => {
    const router = useRouter();

    const close = () => {
        router.push(PAGES.GALLERY);
    };

    return (
        <SelectionBar>
            <FluidContainer>
                <IconButton onClick={close}>
                    <BackButton />
                </IconButton>
                <Box sx={{ marginInline: "auto" }}>{pt("Faces")}</Box>
            </FluidContainer>
        </SelectionBar>
    );
};

interface ClusterDebugPhotoFrameProps {
    files: EnteFile[];
    duplicates?: Duplicate[];
    activeCollectionID: number;
}

const ClusterDebugPhotoFrame: React.FC<ClusterDebugPhotoFrameProps> = ({
    duplicates,
    files,
    activeCollectionID,
}) => {
    const displayFiles = useMemoSingleThreaded(() => {
        return files.map((item) => {
            const filteredItem = {
                ...item,
                w: window.innerWidth,
                h: window.innerHeight,
                title: item.pubMagicMetadata?.data.caption,
            };
            return filteredItem;
        });
    }, [files]);

    const updateURL =
        (index: number) => (id: number, url: string, forceUpdate?: boolean) => {
            const file = displayFiles[index];
            // this is to prevent outdated updateURL call from updating the wrong file
            if (file.id !== id) {
                log.info(
                    `[${id}]PhotoSwipe: updateURL: file id mismatch: ${file.id} !== ${id}`,
                );
                throw Error(CustomError.UPDATE_URL_FILE_ID_MISMATCH);
            }
            if (file.msrc && !forceUpdate) {
                throw Error(CustomError.URL_ALREADY_SET);
            }
            updateFileMsrcProps(file, url);
        };

    const getThumbnail = (
        item: EnteFile,
        index: number,
        isScrolling: boolean,
    ) => (
        <PreviewCard
            key={`tile-${item.id}`}
            file={item}
            updateURL={updateURL(index)}
            onClick={() => {}}
            selectable={false}
            onSelect={() => {}}
            selected={false}
            selectOnClick={false}
            onHover={() => {}}
            onRangeSelect={() => {}}
            isRangeSelectActive={false}
            isInsSelectRange={false}
            activeCollectionID={activeCollectionID}
            showPlaceholder={isScrolling}
        />
    );

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <DedupePhotoList /*PhotoList*/
                        width={width}
                        height={height}
                        getThumbnail={getThumbnail}
                        duplicates={duplicates}
                        activeCollectionID={activeCollectionID}
                        showAppDownloadBanner={false}
                    />
                )}
            </AutoSizer>
        </Container>
    );
};

const Container = styled("div")`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;
    overflow: hidden;
    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;
