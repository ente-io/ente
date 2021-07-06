import React, { useState } from 'react';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';

enum ExportState {
    INIT,
    INPROGRESS,
    FINISHED
}

export default function ExportModal(props) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [exportState, setExportState] = useState(ExportState.INPROGRESS);
    switch (exportState) {
        case ExportState.INIT:
            return (
                <ExportInit {...props} />
            );
        case ExportState.INPROGRESS:
            return (
                <ExportInProgress {...props} />
            );
    }
}
