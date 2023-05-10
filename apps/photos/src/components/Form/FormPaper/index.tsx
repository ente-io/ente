import { Paper, styled } from '@mui/material';

const FormPaper = styled(Paper)(({ theme }) => ({
    padding: theme.spacing(4, 2),
    maxWidth: '360px',
    width: '100%',
    textAlign: 'left',
}));
export default FormPaper;
