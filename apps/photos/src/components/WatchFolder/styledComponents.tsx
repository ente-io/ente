import {} from './../Container';
import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import { VerticallyCentered } from 'components/Container';

export const MappingsContainer = styled(Box)(() => ({
    height: '278px',
    overflow: 'auto',
    '&::-webkit-scrollbar': {
        width: '4px',
    },
}));

export const NoMappingsContainer = styled(VerticallyCentered)({
    textAlign: 'left',
    alignItems: 'flex-start',
    marginBottom: '32px',
});

export const EntryContainer = styled(Box)({
    marginLeft: '12px',
    marginRight: '6px',
    marginBottom: '12px',
});
