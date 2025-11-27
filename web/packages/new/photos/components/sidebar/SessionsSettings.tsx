import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DevicesIcon from "@mui/icons-material/Devices";
import { CircularProgress, Divider, Stack, Typography } from "@mui/material";
import {
    getActiveSessions,
    terminateSession,
    type Session,
} from "ente-accounts/services/sessions";
import { RowButton, RowButtonGroup } from "ente-base/components/RowButton";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import { formattedDateTime } from "ente-base/i18n-date";
import log from "ente-base/log";
import { savedAuthToken } from "ente-base/token";
import { t } from "i18next";
import { useCallback, useEffect, useState } from "react";

export const SessionsSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("active_sessions")}
        >
            <SessionsSettingsContents />
        </TitledNestedSidebarDrawer>
    );
};

const SessionsSettingsContents: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [sessions, setSessions] = useState<Session[] | undefined>(); // storing and displaying the current active sessions
    const [currentToken, setCurrentToken] = useState<string | undefined>(); // to check whether isCurrentDevice
    const [isLoading, setIsLoading] = useState(true); // to show loader on each session termination and inital load
    const [error, setError] = useState<string | undefined>();

    const fetchSessions = useCallback(async () => {
        setIsLoading(true);
        setError(undefined);
        try {
            const [activeSessions, token] = await Promise.all([
                getActiveSessions(),
                savedAuthToken(),
            ]);
            setSessions(activeSessions);
            setCurrentToken(token ?? undefined);
        } catch (e) {
            log.error("Failed to fetch active sessions", e);
            setError(t("generic_error"));
        } finally {
            setIsLoading(false);
        }
    }, []);

    useEffect(() => {
        void fetchSessions();
    }, [fetchSessions]);

    const handleTerminateSession = useCallback(
        (session: Session) => {
            const isCurrentDevice = session.token === currentToken;

            showMiniDialog({
                title: t("terminate_session"),
                message: isCurrentDevice
                    ? t("terminate_session_confirm_message_self")
                    : `${t("terminate_session_confirm_message")}: ${session.prettyUA}`,
                continue: {
                    text: t("terminate"),
                    color: "critical",
                    action: async () => {
                        if (isCurrentDevice) {
                            logout();
                        } else {
                            try {
                                await terminateSession(session.token);
                                await fetchSessions();
                            } catch (e) {
                                log.error("Failed to terminate session", e);
                                showMiniDialog({
                                    title: t("error"),
                                    message: t("terminate_session_failed"),
                                });
                            }
                        }
                    },
                },
            });
        },
        [currentToken, fetchSessions, logout, showMiniDialog],
    );

    if (isLoading) {
        return (
            <Stack
                sx={{
                    flex: 1,
                    alignItems: "center",
                    justifyContent: "center",
                    py: 4,
                }}
            >
                <CircularProgress color="accent" />
            </Stack>
        );
    }

    if (error) {
        return (
            <Stack sx={{ px: 2, py: 2 }}>
                <Typography
                    variant="small"
                    sx={{ color: "critical.main", textAlign: "center" }}
                >
                    {error}
                </Typography>
            </Stack>
        );
    }

    if (!sessions || sessions.length === 0) {
        return (
            <Stack sx={{ px: 2, py: 2 }}>
                <Typography
                    variant="small"
                    sx={{ color: "text.muted", textAlign: "center" }}
                >
                    {t("nothing_here")}
                </Typography>
            </Stack>
        );
    }

    return (
        <Stack sx={{ px: 2, pb: "12px", gap: 2 }}>
            <Typography variant="small" sx={{ px: 0, color: "text.faint" }}>
                {t("active_sessions_hint")}
            </Typography>
            <RowButtonGroup>
                {sessions.map((session, index) => (
                    <SessionRow
                        key={session.token}
                        session={session}
                        isCurrentDevice={session.token === currentToken}
                        onTerminate={() => handleTerminateSession(session)}
                        showDivider={index < sessions.length - 1}
                    />
                ))}
            </RowButtonGroup>
        </Stack>
    );
};

interface SessionRowProps {
    session: Session;
    isCurrentDevice: boolean;
    onTerminate: () => void;
    showDivider: boolean;
}

const SessionRow: React.FC<SessionRowProps> = ({
    session,
    isCurrentDevice,
    onTerminate,
    showDivider,
}) => {
    const lastUsedFormatted = formattedDateTime(session.lastUsedTime);

    return (
        <>
            <RowButton
                startIcon={<DevicesIcon />}
                label={
                    <Stack sx={{ gap: 0.5, alignItems: "flex-start" }}>
                        <Typography
                            sx={{
                                fontWeight: isCurrentDevice ? "bold" : "medium",
                                color: isCurrentDevice
                                    ? "accent.main"
                                    : "text.base",
                                textAlign: "left",
                            }}
                        >
                            {isCurrentDevice
                                ? t("this_device")
                                : session.prettyUA}
                        </Typography>
                        {!isCurrentDevice && (
                            <Typography
                                variant="small"
                                sx={{ color: "text.muted" }}
                            >
                                {session.ip}
                            </Typography>
                        )}
                        <Typography
                            variant="small"
                            sx={{ color: "text.faint" }}
                        >
                            {lastUsedFormatted}
                        </Typography>
                    </Stack>
                }
                endIcon={<ChevronRightIcon />}
                onClick={onTerminate}
            />
            {showDivider && <Divider sx={{ opacity: 0.4 }} />}
        </>
    );
};
