import { DialogContentText, styled } from '@mui/material';

const MessageText = styled(DialogContentText)(({ theme }) => ({
    paddingBottom: theme.spacing(2),
    fontSize: '20px',
    lineHeight: '24.2px',
}));

export default MessageText;
