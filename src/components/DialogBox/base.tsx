import { Dialog, DialogProps, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ fullScreen, theme }) => ({
    '& .MuiDialog-paper': {
        padding: theme.spacing(2, 0),
    },
    '& .MuiDialogTitle-root': {
        padding: theme.spacing(2, 3),
    },
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2, 3),
    },

    '& .MuiDialogActions-root button': {
        width: '100%',
        fontSize: '18px',
        lineHeight: '21.78px',
        padding: theme.spacing(2),
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

DialogBoxBase.defaultProps = {
    fullWidth: true,
    maxWidth: 'sm',
};

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
