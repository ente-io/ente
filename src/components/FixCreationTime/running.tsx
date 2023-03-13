import { ComfySpan } from 'components/ExportInProgress';
import React from 'react';
import { ProgressBar } from 'react-bootstrap';
import { useTranslation } from 'react-i18next';

export default function FixCreationTimeRunning({ progressTracker }) {
    const { t } = useTranslation();
    return (
        <>
            <div style={{ marginBottom: '10px' }}>
                <ComfySpan>
                    {' '}
                    {progressTracker.current} / {progressTracker.total}{' '}
                </ComfySpan>{' '}
                <span style={{ marginLeft: '10px' }}>
                    {' '}
                    {t('CREATION_TIME_UPDATED')}
                </span>
            </div>
            <div
                style={{
                    width: '100%',
                    marginTop: '10px',
                    marginBottom: '20px',
                }}>
                <ProgressBar
                    now={Math.round(
                        (progressTracker.current * 100) / progressTracker.total
                    )}
                    animated={true}
                    variant="upload-progress-bar"
                />
            </div>
        </>
    );
}
