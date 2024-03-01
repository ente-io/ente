import { Button, DialogActions, DialogContent } from "@mui/material";
import { t } from "i18next";

interface Props {
    startExport: () => void;
}
export default function ExportInit({ startExport }: Props) {
    return (
        <DialogContent>
            <DialogActions>
                <Button size="large" color="accent" onClick={startExport}>
                    {t("START")}
                </Button>
            </DialogActions>
        </DialogContent>
    );
}
