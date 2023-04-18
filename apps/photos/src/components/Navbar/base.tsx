import { FlexWrapper } from 'components/Container';
import { styled } from '@mui/material';
import { IMAGE_CONTAINER_MAX_WIDTH, MIN_COLUMNS } from 'constants/gallery';
const NavbarBase = styled(FlexWrapper)`
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 10;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
    background-color: ${({ theme }) => theme.colors.background.base};
    margin-bottom: 16px;
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
`;

export default NavbarBase;
