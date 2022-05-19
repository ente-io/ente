import { Paper, styled } from '@mui/material';

const FormPaper = styled(Paper)(({ theme }) => ({
    padding: theme.spacing(4, 2),
    marginRight: theme.spacing(10),
    [theme.breakpoints.down('md')]: {
        marginRight: theme.spacing(5),
    },
}));
export default FormPaper;
