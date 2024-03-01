interface UploadCancelStatus {
    value: boolean;
}

class UploadCancelService {
    private shouldUploadBeCancelled: UploadCancelStatus = {
        value: false,
    };

    reset() {
        this.shouldUploadBeCancelled.value = false;
    }

    requestUploadCancelation() {
        this.shouldUploadBeCancelled.value = true;
    }

    isUploadCancelationRequested(): boolean {
        return this.shouldUploadBeCancelled.value;
    }
}

export default new UploadCancelService();
