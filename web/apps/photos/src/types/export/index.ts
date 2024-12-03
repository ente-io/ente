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
