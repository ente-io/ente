import {
    Box,
    Button,
    Checkbox,
    Divider,
    FormControlLabel,
    FormGroup,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { RowButtonGroup, RowSwitch } from "ente-base/components/RowButton";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import {
    disableML,
    enableML,
    type MLStatus,
} from "ente-new/photos/services/ml";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { openURL } from "../../utils/web";
import { useMLStatusSnapshot } from "../utils/use-snapshot";
import { useWrapAsyncOperation } from "../utils/use-wrap-async";

export const MLSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const mlStatus = useMLStatusSnapshot();
    const [openFaceConsent, setOpenFaceConsent] = useState(false);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleEnableML = () => setOpenFaceConsent(true);

    const handleConsent = useWrapAsyncOperation(async () => {
        await enableML();
        // Close the FaceConsent drawer, come back to ourselves.
        setOpenFaceConsent(false);
    });

    const handleDisableML = useWrapAsyncOperation(disableML);

    let component: React.ReactNode;
    if (!mlStatus) {
        component = <Loading />;
    } else if (mlStatus.phase == "disabled") {
        component = <EnableML onEnable={handleEnableML} showMagicSearchHint />;
    } else {
        component = (
            <ManageML {...{ mlStatus }} onDisableML={handleDisableML} />
        );
    }

    return (
        <>
            <TitledNestedSidebarDrawer
                {...{ open, onClose }}
                onRootClose={handleRootClose}
                title={t("ml_search")}
            >
                {component}
            </TitledNestedSidebarDrawer>

            <FaceConsentDrawer
                open={openFaceConsent}
                onClose={() => setOpenFaceConsent(false)}
                onRootClose={handleRootClose}
                onConsent={handleConsent}
            />
        </>
    );
};

const Loading: React.FC = () => {
    return (
        <Box sx={{ textAlign: "center", pt: 4 }}>
            <ActivityIndicator />
        </Box>
    );
};

interface EnableMLProps {
    /** Called when the user enables ML. */
    onEnable: () => void;
    /**
     *  If true, a footnote describing the magic search feature will be shown.
     */
    showMagicSearchHint?: boolean;
}

export const EnableML: React.FC<EnableMLProps> = ({
    onEnable,
    showMagicSearchHint,
}) => {
    const moreDetails = () =>
        openURL("https://help.ente.io/photos/features/machine-learning");

    return (
        <Stack sx={{ gap: "32px", py: "20px", px: 2 }}>
            <Typography sx={{ color: "text.muted" }}>
                {t("ml_search_description")}
            </Typography>
            <Stack sx={{ gap: "8px" }}>
                <Button fullWidth color="accent" onClick={onEnable}>
                    {t("enable")}
                </Button>
                <Button fullWidth color="secondary" onClick={moreDetails}>
                    {t("more_details")}
                </Button>
            </Stack>
            {showMagicSearchHint && (
                <Typography variant="small" sx={{ color: "text.faint" }}>
                    {t("ml_search_footnote")}
                </Typography>
            )}
        </Stack>
    );
};

type FaceConsentDrawerProps = NestedSidebarDrawerVisibilityProps &
    Pick<FaceConsentProps, "onConsent">;

const FaceConsentDrawer: React.FC<FaceConsentDrawerProps> = ({
    open,
    onClose,
    onRootClose,
    onConsent,
}) => {
    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("ml_consent_title")}
        >
            <FaceConsent onConsent={onConsent} onCancel={onClose} />
        </TitledNestedSidebarDrawer>
    );
};

interface FaceConsentProps {
    /** Called when the user provides their consent. */
    onConsent: () => void;
    /** Called when the user cancels out. */
    onCancel: () => void;
}

export const FaceConsent: React.FC<FaceConsentProps> = ({
    onConsent,
    onCancel,
}) => {
    const [acceptTerms, setAcceptTerms] = useState(false);

    useEffect(() => {
        setAcceptTerms(false);
    }, []);

    const privacyPolicyLink = (
        <Link
            target="_blank"
            href="https://ente.io/privacy#8-biometric-information-privacy-policy"
            underline="always"
            sx={{ color: "inherit", textDecorationColor: "inherit" }}
        />
    );

    return (
        <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
            <Typography component="div" sx={{ color: "text.muted", px: "8px" }}>
                <Trans
                    i18nKey={"ml_consent_description"}
                    components={{ a: privacyPolicyLink }}
                />
            </Typography>
            <FormGroup sx={{ width: "100%" }}>
                <FormControlLabel
                    sx={{ color: "text.muted", ml: 0, mt: 2 }}
                    control={
                        <Checkbox
                            size="small"
                            checked={acceptTerms}
                            onChange={(e) => setAcceptTerms(e.target.checked)}
                        />
                    }
                    label={t("ml_consent_confirmation")}
                />
            </FormGroup>
            <Stack sx={{ gap: "8px", px: "8px" }}>
                <FocusVisibleButton
                    fullWidth
                    color="accent"
                    disabled={!acceptTerms}
                    onClick={onConsent}
                >
                    {t("ml_consent")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onCancel}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </Stack>
    );
};

interface ManageMLProps {
    /** The {@link MLStatus}; a non-disabled one. */
    mlStatus: Exclude<MLStatus, { phase: "disabled" }>;
    /** Called when the user wants to disable ML. */
    onDisableML: () => void;
}

const ManageML: React.FC<ManageMLProps> = ({ mlStatus, onDisableML }) => {
    const { showMiniDialog } = useBaseContext();

    const { phase, phaseFailed, nSyncedFiles, nTotalFiles } = mlStatus;

    let status: string;
    switch (phase) {
        case "scheduled":
            status = t("indexing_status_scheduled");
            break;
        case "fetching":
            status = t("indexing_status_fetching");
            break;
        case "indexing":
            status = t("indexing_status_running");
            break;
        case "clustering":
            status = t("people");
            break;
        default:
            status = phaseFailed ? t("error") : t("indexing_status_done");
            break;
    }

    // Show processed as percentages instead of potentially confusing counts.
    const processed = `${nTotalFiles ? Math.round((100 * nSyncedFiles) / nTotalFiles) : 100}%`;

    const confirmDisableML = () =>
        showMiniDialog({
            title: t("ml_search_disable"),
            message: t("ml_search_disable_confirm"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: onDisableML,
            },
        });

    return (
        <Stack sx={{ px: "16px", py: "20px", gap: 4 }}>
            <Stack sx={{ gap: 3 }}>
                <RowButtonGroup>
                    <RowSwitch
                        label={t("enabled")}
                        checked={true}
                        onClick={confirmDisableML}
                    />
                </RowButtonGroup>
            </Stack>

            <Stack>
                <Stack
                    direction="row"
                    sx={{
                        gap: 2,
                        px: 2,
                        pt: 1,
                        pb: 2,
                        justifyContent: "space-between",
                    }}
                >
                    <Typography sx={{ color: "text.faint" }}>
                        {t("indexing")}
                    </Typography>
                    <Typography>{status}</Typography>
                </Stack>
                <Divider sx={{ mx: 1.5 }} />
                <Stack
                    direction="row"
                    sx={{
                        gap: 2,
                        px: 2,
                        pt: 2,
                        pb: 1,
                        justifyContent: "space-between",
                    }}
                >
                    <Typography sx={{ color: "text.faint" }}>
                        {t("processed")}
                    </Typography>
                    <Typography sx={{ textAlign: "right" }}>
                        {processed}
                    </Typography>
                </Stack>
            </Stack>
        </Stack>
    );
};
