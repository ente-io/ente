import { styled } from '@mui/material/styles';
import VerticallyCentered from 'components/Container';

const FormContainer = styled(VerticallyCentered)(({ theme }) => ({
    alignItems: 'center',

    [theme.breakpoints.down('md')]: {
        paddingRight: theme.spacing(5),
    },
}));

export default FormContainer;
