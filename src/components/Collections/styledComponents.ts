import { PaddedContainer } from 'components/Container';
import styled from 'styled-components';

export const CollectionBarWrapper = styled(PaddedContainer)`
    display: flex;
    position: relative;
    overflow: hidden;
    height: 86px;
    width: 100%;
    margin: 10px auto;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
`;

export const CollectionSectionWrapper = styled(PaddedContainer)`
    margin-bottom: 8px;
    margin-top: 16px;
`;

export const ScrollContainer = styled.div`
    width: 100%;
    height: 100px;
    overflow: auto;
    max-width: 100%;
    scroll-behavior: smooth;
    display: flex;
`;

export const CollectionTile = styled.div`
    display: flex;
    position: relative;
    border-radius: 4px;
    user-select: none;
    cursor: pointer;
    background-size: cover;
    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
        flex: 1;
        pointer-events: none;
    }
`;

export const CollectionTileWrapper = styled.div`
    margin-right: 4px;
`;

export const ActiveIndicator = styled.div`
    height: 3px;
    background-color: ${({ theme }) => theme.palette.text.primary};
    margin-top: 18px;
    border-radius: 2px;
`;

export const Hider = styled.div<{ hide: boolean }>`
    display: ${(props) => (props.hide ? 'none' : 'block')};
`;

export const CollectionBarTile = styled(CollectionTile)`
    width: 80px;
    height: 64px;
`;

export const AllCollectionTile = styled(CollectionTile)`
    width: 150px;
    height: 150px;
    align-items: flex-start;
    margin: 2px;
`;

export const CollectionTitleWithDashedBorder = styled(CollectionTile)`
    border: 1px dashed ${({ theme }) => theme.palette.grey.A200};
`;

export const CollectionSelectorTile = styled(AllCollectionTile)`
    height: 192px;
    width: 192px;
    margin: 10px;
`;

export const ResultPreviewTile = styled(AllCollectionTile)`
    width: 48px;
    height: 48px;
    border-radius: 4px;
`;

export const CollectionTileTextOverlay = styled.div`
    height: 100%;
    width: 100%;
    position: absolute;
    font-size: 14px;
    line-height: 20px;
    padding: 4px 6px;
`;

export const CollectionBarTileText = styled(CollectionTileTextOverlay)`
    background: linear-gradient(
        180deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
    display: flex;
    align-items: flex-end;
`;

export const AllCollectionTileText = styled(CollectionTileTextOverlay)`
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;
