import Container from 'components/Container';
import styled from 'styled-components';

export const QRCode = styled.img`
    height: 200px;
    width: 200px;
    margin: ${({ theme }) => theme.spacing(2)};
`;

export const LoadingQRCode = styled(Container)(({ theme }) => ({
    flex: '0 0 200px',
    border: `1px solid ${theme.palette.grey[700]}`,
    width: 200,
    margin: theme.spacing(2),
}));
