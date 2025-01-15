import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { DialogActions, DialogContent } from "@mui/material";
import { t } from "i18next";

interface Props {
    startExport: () => void;
}
export default function ExportInit({ startExport }: Props) {
    return (
        <DialogContent>
            <DialogActions>
                <FocusVisibleButton
                    fullWidth
                    color="accent"
                    onClick={startExport}
                >
                    {t("start")}
                </FocusVisibleButton>
            </DialogActions>
        </DialogContent>
    );
}
