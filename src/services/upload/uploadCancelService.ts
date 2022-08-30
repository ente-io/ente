interface UploadCancelStatus {
    val: boolean;
}

class UploadCancelService {
    private shouldUploadBeCancelled: UploadCancelStatus = {
        val: false,
    };

    reset() {
        this.shouldUploadBeCancelled.val = false;
    }

    signalCancelUpload() {
        this.shouldUploadBeCancelled.val = true;
    }

    isUploadCancelationRequested(): boolean {
        return this.shouldUploadBeCancelled.val;
    }
}

export default new UploadCancelService();
