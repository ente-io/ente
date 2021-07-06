import React, { useState } from 'react';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';

enum ExportState {
    INIT,
    INPROGRESS,
    FINISHED
}

export default function ExportModal(props) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [exportState, setExportState] = useState(ExportState.FINISHED);
    switch (exportState) {
        case ExportState.INIT:
            return (
                <ExportInit {...props} />
            );
        case ExportState.INPROGRESS:
            return (
                <ExportInProgress {...props} />
            );
        case ExportState.FINISHED:
            return (
                <ExportFinished {...props} />
            );
    }
}
