import { UploadProgressBar } from "./progressBar";
import { UploadProgressTitle } from "./title";

export function UploadProgressHeader() {
    return (
        <>
            <UploadProgressTitle />
            <UploadProgressBar />
        </>
    );
}
