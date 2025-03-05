import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { EnteFile } from "@/media/file";
import { ItemCard, PreviewItemTile } from "@/new/photos/components/Tiles";
import { FlexWrapper } from "@ente/shared/components/Container";
import { Box, styled } from "@mui/material";
import ItemList from "components/ItemList";
import { t } from "i18next";

interface Iprops {
    isOpen: boolean;
    onClose: () => void;
    allCollectionsNameByID: Map<number, string>;
    pendingExports: EnteFile[];
}

export const ItemContainer = styled("div")`
    position: relative;
    top: 5px;
    display: inline-block;
    max-width: 394px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
`;

const ExportPendingList = (props: Iprops) => {
    const renderListItem = (file: EnteFile) => {
        return (
            <FlexWrapper>
                <Box sx={{ marginRight: "8px" }}>
                    <ItemCard
                        key={file.id}
                        TileComponent={PreviewItemTile}
                        coverFile={file}
                    />
                </Box>
                <ItemContainer>
                    {`${props.allCollectionsNameByID.get(file.collectionID)} / ${
                        file.metadata.title
                    }`}
                </ItemContainer>
            </FlexWrapper>
        );
    };

    const getItemTitle = (file: EnteFile) => {
        return `${props.allCollectionsNameByID.get(file.collectionID)} / ${
            file.metadata.title
        }`;
    };

    const generateItemKey = (file: EnteFile) => {
        return `${file.collectionID}-${file.id}`;
    };

    return (
        <TitledMiniDialog
            open={props.isOpen}
            onClose={props.onClose}
            paperMaxWidth="444px"
            title={t("pending_items")}
        >
            <ItemList
                maxHeight={240}
                itemSize={50}
                items={props.pendingExports}
                renderListItem={renderListItem}
                getItemTitle={getItemTitle}
                generateItemKey={generateItemKey}
            />
            <FocusVisibleButton
                fullWidth
                color="secondary"
                onClick={props.onClose}
            >
                {t("close")}
            </FocusVisibleButton>
        </TitledMiniDialog>
    );
};

export default ExportPendingList;
