import { IMAGE_CONTAINER_MAX_WIDTH, MIN_COLUMNS } from 'constants/gallery';
import { css } from 'styled-components';

export const SpecialPadding = css`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
`;
