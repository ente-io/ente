import { Dialog } from "@mui/material";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import { SetLoading } from "types/gallery";
import PlanSelectorCard from "./card";

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
            PaperProps={{
                sx: (theme) => ({
                    width: "391px",
                    p: 1,
                    [theme.breakpoints.down(360)]: { p: 0 },
                }),
            }}
        >
            <PlanSelectorCard
                closeModal={props.closeModal}
                setLoading={props.setLoading}
            />
        </Dialog>
    );
}

export default PlanSelector;
