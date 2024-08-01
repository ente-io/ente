import { Dialog, useMediaQuery, useTheme } from "@mui/material";
import { SetLoading } from "types/gallery";
import PlanSelectorCard from "./card";

interface PlanSelectorProps {
    modalView: boolean;
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelector(props: PlanSelectorProps) {
    const fullScreen = useMediaQuery(useTheme().breakpoints.down("sm"));

    if (!props.modalView) {
        return <></>;
    }

    return (
        <Dialog
            {...{ fullScreen }}
            open={props.modalView}
            onClose={props.closeModal}
            PaperProps={{
                sx: (theme) => ({
                    width: { sm: "391px" },
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
