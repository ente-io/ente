import { Dialog, DialogProps, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ fullScreen, theme }) => ({
    '& .MuiDialogActions-root button': {
        width: '100%',
    },
    ...(fullScreen
        ? {
              '& .MuiDialogActions-root': {
                  padding: theme.spacing(2, 3),
                  flexDirection: 'column-reverse',
              },
              '& .MuiDialogActions-root button:not(:first-child)': {
                  margin: 0,
                  marginBottom: theme.spacing(1),
              },
          }
        : {
              '& .MuiDialogActions-root': {
                  padding: theme.spacing(2, 3),
              },
              '& .MuiDialogActions-root button:not(:first-child)': {
                  margin: 0,
                  marginLeft: theme.spacing(2),
              },
          }),
}));

export const dialogCloseHandler =
    ({
        staticBackdrop,
        nonClosable,
        onClose,
    }: {
        staticBackdrop?: boolean;
        nonClosable?: boolean;
        onClose: () => void;
    }): DialogProps['onClose'] =>
    (_, reason) => {
        if (nonClosable) {
            // no-op
        } else if (staticBackdrop && reason === 'backdropClick') {
            // no-op
        } else {
            onClose();
        }
    };

export default DialogBoxBase;
