import {
    FileUploadResults,
    RANDOM_PERCENTAGE_PROGRESS_FOR_PUT,
    UPLOAD_STAGES,
} from 'constants/upload';
import { ProgressUpdater } from 'types/upload';

class UIService {
    private perFileProgress: number;
    private filesUploaded: number;
    private totalFileCount: number;
    private fileProgress: Map<number, number>;
    private uploadResult: Map<number, FileUploadResults>;
    private progressUpdater: ProgressUpdater;

    init(progressUpdater: ProgressUpdater) {
        this.progressUpdater = progressUpdater;
    }

    reset(count: number) {
        this.setTotalFileCount(count);
        this.filesUploaded = 0;
        this.fileProgress = new Map<number, number>();
        this.uploadResult = new Map<number, FileUploadResults>();
        this.updateProgressBarUI();
    }

    setTotalFileCount(count: number) {
        this.totalFileCount = count;
        this.perFileProgress = 100 / this.totalFileCount;
    }

    setFileProgress(key: number, progress: number) {
        this.fileProgress.set(key, progress);
        this.updateProgressBarUI();
    }

    setUploadStage(stage: UPLOAD_STAGES) {
        this.progressUpdater.setUploadStage(stage);
    }

    setPercentComplete(percent: number) {
        this.progressUpdater.setPercentComplete(percent);
    }

    setFilenames(filenames: Map<number, string>) {
        this.progressUpdater.setFilenames(filenames);
    }

    increaseFileUploaded() {
        this.filesUploaded++;
        this.updateProgressBarUI();
    }

    moveFileToResultList(key: number, uploadResult: FileUploadResults) {
        this.uploadResult.set(key, uploadResult);
        this.fileProgress.delete(key);
        this.updateProgressBarUI();
    }

    updateProgressBarUI() {
        const {
            setPercentComplete,
            setFileCounter,
            setFileProgress,
            setUploadResult,
        } = this.progressUpdater;
        setFileCounter({
            finished: this.filesUploaded,
            total: this.totalFileCount,
        });
        let percentComplete = this.perFileProgress * this.uploadResult.size;
        if (this.fileProgress) {
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            for (const [_, progress] of this.fileProgress) {
                // filter  negative indicator values during percentComplete calculation
                if (progress < 0) {
                    continue;
                }
                percentComplete += (this.perFileProgress * progress) / 100;
            }
        }
        setPercentComplete(percentComplete);
        setFileProgress(this.fileProgress);
        setUploadResult(this.uploadResult);
    }

    trackUploadProgress(
        fileLocalID: number,
        percentPerPart = RANDOM_PERCENTAGE_PROGRESS_FOR_PUT(),
        index = 0
    ) {
        const cancel = { exec: null };
        let timeout = null;
        const resetTimeout = () => {
            if (timeout) {
                clearTimeout(timeout);
            }
            timeout = setTimeout(() => cancel.exec(), 30 * 1000);
        };
        return {
            cancel,
            onUploadProgress: (event) => {
                this.fileProgress.set(
                    fileLocalID,
                    Math.min(
                        Math.round(
                            percentPerPart * index +
                                (percentPerPart * event.loaded) / event.total
                        ),
                        98
                    )
                );
                this.updateProgressBarUI();
                if (event.loaded === event.total) {
                    clearTimeout(timeout);
                } else {
                    resetTimeout();
                }
            },
        };
    }
}

export default new UIService();
