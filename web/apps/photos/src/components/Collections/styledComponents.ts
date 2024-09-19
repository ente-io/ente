import { Overlay } from "@ente/shared/components/Container";
import { Box, styled } from "@mui/material";
import {
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
} from "components/PhotoList/constants";

export const CollectionListWrapper = styled(Box)`
    position: relative;
    overflow: hidden;
    height: 86px;
    width: 100%;
`;

export const CollectionListBarWrapper = styled(Box)`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
    margin-bottom: 16px;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
`;

export const CollectionInfoBarWrapper = styled(Box)`
    width: 100%;
    margin-bottom: 12px;
`;

export const ScrollContainer = styled("div")`
    width: 100%;
    height: 120px;
    overflow: auto;
    scroll-behavior: smooth;
    display: flex;
    gap: 4px;
`;

/** See also: {@link ItemTile}. */
export const CollectionTile = styled("div")`
    display: flex;
    position: relative;
    border-radius: 4px;
    overflow: hidden;
    cursor: pointer;
    & > img {
        object-fit: cover;
        width: 100%;
        height: 100%;
        pointer-events: none;
    }
    user-select: none;
`;

export const AllCollectionTile = styled(CollectionTile)`
    width: 150px;
    height: 150px;
`;

export const AllCollectionTileText = styled(Overlay)`
    padding: 8px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;
