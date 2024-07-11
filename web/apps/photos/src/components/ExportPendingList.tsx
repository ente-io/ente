import { EnteFile } from "@/new/photos/types/file";
import { FlexWrapper } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import { Box, styled } from "@mui/material";
import ItemList from "components/ItemList";
import { t } from "i18next";
import CollectionCard from "./Collections/CollectionCard";
import { ResultPreviewTile } from "./Collections/styledComponents";

interface Iprops {
    isOpen: boolean;
    onClose: () => void;
    collectionNameMap: Map<number, string>;
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
                    <CollectionCard
                        key={file.id}
                        coverFile={file}
                        onClick={() => null}
                        collectionTile={ResultPreviewTile}
                    />
                </Box>
                <ItemContainer>
                    {`${props.collectionNameMap.get(file.collectionID)} / ${
                        file.metadata.title
                    }`}
                </ItemContainer>
            </FlexWrapper>
        );
    };

    const getItemTitle = (file: EnteFile) => {
        return `${props.collectionNameMap.get(file.collectionID)} / ${
            file.metadata.title
        }`;
    };

    const generateItemKey = (file: EnteFile) => {
        return `${file.collectionID}-${file.id}`;
    };

    return (
        <DialogBoxV2
            open={props.isOpen}
            onClose={props.onClose}
            PaperProps={{
                sx: { maxWidth: "444px" },
            }}
            attributes={{
                title: t("PENDING_ITEMS"),
                close: {
                    action: props.onClose,
                    text: t("CLOSE"),
                },
            }}
        >
            <ItemList
                maxHeight={240}
                itemSize={50}
                items={props.pendingExports}
                renderListItem={renderListItem}
                getItemTitle={getItemTitle}
                generateItemKey={generateItemKey}
            />
        </DialogBoxV2>
    );
};

export default ExportPendingList;
