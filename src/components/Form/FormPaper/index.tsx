import { Paper, styled } from '@mui/material';

const FormPaper = styled(Paper)(({ theme }) => ({
    padding: theme.spacing(4, 2),
    maxWidth: '360px',
    marginRight: theme.spacing(10),
    [theme.breakpoints.down('md')]: {
        marginRight: theme.spacing(5),
    },
    textAlign: 'left',
}));
export default FormPaper;
