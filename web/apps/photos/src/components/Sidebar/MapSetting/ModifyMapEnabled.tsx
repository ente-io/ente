import log from "@/next/log";
import { Box, DialogProps } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import DisableMap from "../DisableMap";
import EnableMap from "../EnableMap";

const ModifyMapEnabled = ({ open, onClose, onRootClose, mapEnabled }) => {
    const { somethingWentWrong, updateMapEnabled } = useContext(AppContext);

    const disableMap = async () => {
        try {
            await updateMapEnabled(false);
            onClose();
        } catch (e) {
            log.error("Disable Map failed", e);
            somethingWentWrong();
        }
    };

    const enableMap = async () => {
        try {
            await updateMapEnabled(true);
            onClose();
        } catch (e) {
            log.error("Enable Map failed", e);
            somethingWentWrong();
        }
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };

    return (
        <Box>
            <EnteDrawer
                anchor="left"
                transitionDuration={0}
                open={open}
                onClose={handleDrawerClose}
                slotProps={{
                    backdrop: {
                        sx: { "&&&": { backgroundColor: "transparent" } },
                    },
                }}
            >
                {mapEnabled ? (
                    <DisableMap
                        onClose={onClose}
                        disableMap={disableMap}
                        onRootClose={handleRootClose}
                    />
                ) : (
                    <EnableMap
                        onClose={onClose}
                        enableMap={enableMap}
                        onRootClose={handleRootClose}
                    />
                )}
            </EnteDrawer>
        </Box>
    );
};

export default ModifyMapEnabled;
