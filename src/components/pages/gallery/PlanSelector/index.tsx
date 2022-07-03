import React, { useContext } from 'react';
import { SetLoading } from 'types/gallery';
import { AppContext } from 'pages/_app';
import { Box, Dialog } from '@mui/material';
import PlanSelectorCard from './card';

interface Props {
    modalView: boolean;
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelector(props: Props) {
    const appContext = useContext(AppContext);
    if (!props.modalView) {
        return <></>;
    }

    return (
        <Dialog
            fullScreen={appContext.isMobile}
            open={props.modalView}
            onClose={props.closeModal}
            PaperProps={{ sx: { width: '400px' } }}>
            <Box p={1}>
                <PlanSelectorCard
                    closeModal={props.closeModal}
                    setLoading={props.setLoading}
                />
            </Box>
        </Dialog>
    );
}

export default PlanSelector;
