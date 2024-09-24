import { Overlay } from "@ente/shared/components/Container";
import { styled } from "@mui/material";

export const ScrollContainer = styled("div")`
    width: 100%;
    height: 120px;
    overflow: auto;
    scroll-behavior: smooth;
    display: flex;
    gap: 4px;
`;

export const AllCollectionTileText = styled(Overlay)`
    padding: 8px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;
