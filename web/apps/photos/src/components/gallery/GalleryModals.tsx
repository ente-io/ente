import React from 'react';
import { PlanSelector } from 'ente-new/photos/components/PlanSelector';
import { SingleInputDialog } from 'ente-base/components/SingleInputDialog';
import { WhatsNew } from 'ente-new/photos/components/WhatsNew';
import { t } from 'i18next';

interface GalleryModalsProps {
    // Modal states - using simplified visibility props
    planSelectorVisible: boolean;
    whatsNewVisible: boolean;
    albumNameInputVisible: boolean;
    
    // Modal handlers
    onClosePlanSelector: () => void;
    onCloseWhatsNew: () => void;
    onCloseAlbumNameInput: () => void;
    onAlbumNameSubmit: (name: string) => Promise<void>;
    setLoading: (loading: boolean) => void;
}

/**
 * Simplified container for essential gallery modals
 */
export const GalleryModals: React.FC<GalleryModalsProps> = ({
    planSelectorVisible,
    whatsNewVisible,
    albumNameInputVisible,
    onClosePlanSelector,
    onCloseWhatsNew,
    onCloseAlbumNameInput,
    onAlbumNameSubmit,
    setLoading,
}) => {
    return (
        <>
            {/* Plan Selector Modal */}
            {planSelectorVisible && (
                <PlanSelector
                    open={planSelectorVisible}
                    onClose={onClosePlanSelector}
                    setLoading={setLoading}
                />
            )}

            {/* What's New Dialog */}
            {whatsNewVisible && (
                <WhatsNew 
                    open={whatsNewVisible}
                    onClose={onCloseWhatsNew}
                />
            )}

            {/* Album Name Input Dialog */}
            {albumNameInputVisible && (
                <SingleInputDialog
                    open={albumNameInputVisible}
                    onClose={onCloseAlbumNameInput}
                    title={t("new_album")}
                    label={t("album_name")}
                    submitButtonTitle={t("create")}
                    onSubmit={onAlbumNameSubmit}
                />
            )}
        </>
    );
};
