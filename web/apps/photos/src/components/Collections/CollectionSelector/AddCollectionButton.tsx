import { CenteredFlex, Overlay } from "@ente/shared/components/Container";
import { styled } from "@mui/material";
import CollectionCard from "components/Collections/CollectionCard";
import {
    AllCollectionTile,
    AllCollectionTileText,
} from "components/Collections/styledComponents";
import { t } from "i18next";

const ImageContainer = styled(Overlay)`
    display: flex;
    font-size: 42px;
`;

interface Iprops {
    showNextModal: () => void;
}

export default function AddCollectionButton({ showNextModal }: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            onClick={() => showNextModal()}
            coverFile={null}
        >
            <AllCollectionTileText>
                {t("CREATE_COLLECTION")}
            </AllCollectionTileText>
            <ImageContainer>
                <CenteredFlex>+</CenteredFlex>
            </ImageContainer>
        </CollectionCard>
    );
}
