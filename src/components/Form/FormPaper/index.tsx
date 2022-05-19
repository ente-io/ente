import { Paper, styled } from '@mui/material';

const FormPaper = styled(Paper)(({ theme }) => ({
    padding: theme.spacing(4, 2),
    width: '360px',
    marginRight: theme.spacing(10),
    [theme.breakpoints.down('md')]: {
        marginRight: theme.spacing(5),
    },
    '.MuiButton-root': {
        margin: '32px 0',
    },
}));
export default FormPaper;
