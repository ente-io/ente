import { Paper, styled, Theme } from '@mui/material';

const FormPaper = styled(Paper)(({ theme }: { theme: Theme }) => ({
    padding: theme.spacing(4, 2),
    maxWidth: '360px',
    width: '100%',
    textAlign: 'left',
}));
export default FormPaper;
