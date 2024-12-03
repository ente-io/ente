import { EnteFile } from "@/media/file";
import type { ExportStage } from "services/export";

export interface ExportProgress {
    success: number;
    failed: number;
    total: number;
}

export interface ExportSettings {
    folder: string;
    continuousExport: boolean;
}

export interface ExportUIUpdaters {
    setExportStage: (stage: ExportStage) => void;
    setExportProgress: (progress: ExportProgress) => void;
    setLastExportTime: (exportTime: number) => void;
    setPendingExports: (pendingExports: EnteFile[]) => void;
}
