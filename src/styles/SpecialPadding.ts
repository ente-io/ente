import { IMAGE_CONTAINER_MAX_WIDTH } from 'constants/gallery';
import { css } from 'styled-components';

export const SpecialPadding = css`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
`;
