import CloseIcon from "@mui/icons-material/Close";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import {
    Avatar,
    Box,
    Button,
    CircularProgress,
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { ensureLocalUser } from "ente-accounts-rs/services/user";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { SidebarDrawer } from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import { isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import { t } from "i18next";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
    canManageCollectionSharing,
    type LockerCollection,
    type LockerCollectionParticipant,
} from "types";

interface LockerCollectionShareDrawerProps {
    open: boolean;
    collection: LockerCollection | null;
    onClose: () => void;
    onShareCollection: (collectionID: number, email: string) => Promise<void>;
    onUnshareCollection: (collectionID: number, email: string) => Promise<void>;
    onRefreshSharees?: (
        collectionID: number,
    ) => Promise<LockerCollectionParticipant[]>;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const LockerCollectionShareDrawer: React.FC<
    LockerCollectionShareDrawerProps
> = ({
    open,
    collection,
    onClose,
    onShareCollection,
    onUnshareCollection,
    onRefreshSharees,
}) => {
    const { showMiniDialog } = useBaseContext();
    const currentUser = ensureLocalUser();
    const [sharees, setSharees] = useState<LockerCollectionParticipant[]>([]);
    const [isRefreshingSharees, setIsRefreshingSharees] = useState(false);
    const [addViewerOpen, setAddViewerOpen] = useState(false);
    const [viewerEmail, setViewerEmail] = useState("");
    const [viewerEmailError, setViewerEmailError] = useState<string | null>(
        null,
    );
    const [isSubmittingViewer, setIsSubmittingViewer] = useState(false);

    const ownerEmail =
        collection?.owner.email?.trim() ||
        (collection?.owner.id === currentUser.id ? currentUser.email : "");
    const canManageParticipants = !!(
        collection && canManageCollectionSharing(collection, currentUser.id)
    );

    useEffect(() => {
        if (!open || !collection) {
            setAddViewerOpen(false);
            setViewerEmail("");
            setViewerEmailError(null);
            setIsSubmittingViewer(false);
            setSharees([]);
            return;
        }

        setSharees(collection.sharees);
    }, [collection, open]);

    useEffect(() => {
        if (
            !open ||
            !collection ||
            !onRefreshSharees ||
            (!collection.isShared &&
                !collection.sharees.some((participant) => !participant.email))
        ) {
            return;
        }

        let cancelled = false;
        setIsRefreshingSharees(true);
        void onRefreshSharees(collection.id)
            .then((nextSharees) => {
                if (!cancelled) {
                    setSharees(nextSharees);
                }
            })
            .catch((error: unknown) => {
                log.error(
                    `[LockerCollectionShareDrawer] Failed to refresh sharees for ${collection.id}`,
                    error,
                );
            })
            .finally(() => {
                if (!cancelled) {
                    setIsRefreshingSharees(false);
                }
            });

        return () => {
            cancelled = true;
        };
    }, [collection, onRefreshSharees, open]);

    const sortedSharees = useMemo(
        () =>
            [...sharees].sort((a, b) => {
                if (a.id === currentUser.id && b.id !== currentUser.id)
                    return -1;
                if (a.id !== currentUser.id && b.id === currentUser.id)
                    return 1;
                return (a.email ?? "").localeCompare(b.email ?? "");
            }),
        [currentUser.id, sharees],
    );

    const handleCloseAddViewer = useCallback(() => {
        if (isSubmittingViewer) {
            return;
        }
        setAddViewerOpen(false);
        setViewerEmail("");
        setViewerEmailError(null);
    }, [isSubmittingViewer]);

    const handleAddViewer = useCallback(async () => {
        if (!collection) {
            return;
        }

        const normalizedEmail = viewerEmail.trim().toLowerCase();

        if (!normalizedEmail) {
            setViewerEmailError(t("enterViewerEmail"));
            return;
        }
        if (!EMAIL_PATTERN.test(normalizedEmail)) {
            setViewerEmailError(t("enterValidEmail"));
            return;
        }
        if (normalizedEmail === currentUser.email.toLowerCase()) {
            setViewerEmailError(t("cannotShareWithYourself"));
            return;
        }
        if (
            sortedSharees.some(
                (sharee) => sharee.email?.toLowerCase() === normalizedEmail,
            )
        ) {
            setViewerEmailError(t("viewerAlreadyHasAccess"));
            return;
        }

        setIsSubmittingViewer(true);
        setViewerEmailError(null);
        try {
            await onShareCollection(collection.id, normalizedEmail);
            handleCloseAddViewer();
        } catch (error) {
            if (isHTTPErrorWithStatus(error, 402)) {
                setViewerEmailError(t("sharingRequiresPaidPlan"));
            } else if (isHTTPErrorWithStatus(error, 404)) {
                setViewerEmailError(t("viewerEmailNotOnEnte"));
            } else if (error instanceof Error) {
                setViewerEmailError(error.message);
            } else {
                setViewerEmailError(t("failedToShareCollection"));
            }
        } finally {
            setIsSubmittingViewer(false);
        }
    }, [
        collection,
        currentUser.email,
        handleCloseAddViewer,
        onShareCollection,
        sortedSharees,
        viewerEmail,
    ]);

    const confirmRemoveViewer = useCallback(
        (participant: LockerCollectionParticipant) => {
            if (!collection || !participant.email) {
                return;
            }

            showMiniDialog({
                title: t("removeParticipant"),
                message: t("removeParticipantConfirmation", {
                    email: participant.email,
                }),
                continue: {
                    text: t("remove"),
                    color: "critical",
                    action: async () => {
                        await onUnshareCollection(
                            collection.id,
                            participant.email!,
                        );
                        setSharees((current) =>
                            current.filter(
                                (sharee) =>
                                    sharee.email?.toLowerCase() !==
                                    participant.email!.toLowerCase(),
                            ),
                        );
                    },
                },
            });
        },
        [collection, onUnshareCollection, showMiniDialog],
    );

    if (!collection) {
        return null;
    }

    const participants = [
        {
            participant: {
                id: collection.owner.id,
                email: ownerEmail || t("unknownEmail"),
            },
            subtitle: t("owner"),
            action: undefined,
        },
        ...sortedSharees.map((participant) => ({
            participant,
            subtitle:
                participant.id === currentUser.id
                    ? t("sharedWithYou")
                    : undefined,
            action:
                canManageParticipants &&
                participant.id !== currentUser.id &&
                participant.email ? (
                    <OverflowMenu
                        ariaID={`sharee-${participant.id}`}
                        triggerButtonIcon={<MoreVertIcon />}
                        triggerButtonSxProps={{ color: "text.faint" }}
                    >
                        <OverflowMenuOption
                            color="critical"
                            onClick={() => confirmRemoveViewer(participant)}
                        >
                            {t("removeParticipant")}
                        </OverflowMenuOption>
                    </OverflowMenu>
                ) : undefined,
        })),
    ];

    return (
        <>
            <SidebarDrawer anchor="right" open={open} onClose={onClose}>
                <Stack sx={{ gap: 2, py: 1 }}>
                    <Stack
                        direction="row"
                        sx={{
                            justifyContent: "space-between",
                            alignItems: "flex-start",
                            px: 1,
                        }}
                    >
                        <Box sx={{ px: 1, pt: 1.5 }}>
                            <Typography variant="h3">
                                {collection.name}
                            </Typography>
                            <Typography
                                variant="small"
                                sx={{ mt: 0.5, color: "text.muted" }}
                            >
                                {t("sharedWith")}
                            </Typography>
                        </Box>
                        <IconButton onClick={onClose} color="secondary">
                            <CloseIcon />
                        </IconButton>
                    </Stack>

                    <Stack sx={{ px: 1.5, gap: 1.5 }}>
                        {isRefreshingSharees && (
                            <Stack
                                direction="row"
                                sx={{
                                    alignItems: "center",
                                    justifyContent: "flex-end",
                                    px: 0.5,
                                }}
                            >
                                <CircularProgress size={16} />
                            </Stack>
                        )}

                        <Box
                            sx={(theme) => ({
                                overflow: "hidden",
                                borderRadius: "16px",
                                backgroundColor: theme.vars.palette.fill.faint,
                            })}
                        >
                            {participants.map((row, index) => (
                                <Box
                                    key={`${row.participant.id}-${row.participant.email ?? index}`}
                                    sx={(theme) => ({
                                        borderTop:
                                            index === 0
                                                ? "none"
                                                : `1px solid ${theme.vars.palette.divider}`,
                                    })}
                                >
                                    <ParticipantRow
                                        participant={row.participant}
                                        subtitle={row.subtitle}
                                        action={row.action}
                                    />
                                </Box>
                            ))}
                        </Box>

                        {sortedSharees.length === 0 && (
                            <Typography
                                variant="small"
                                sx={{
                                    px: 0.5,
                                    color: "text.muted",
                                    lineHeight: 1.5,
                                }}
                            >
                                {t("noSharedUsers")}
                            </Typography>
                        )}

                        {canManageParticipants && (
                            <Button
                                variant="contained"
                                onClick={() => setAddViewerOpen(true)}
                                sx={{
                                    minHeight: 48,
                                    borderRadius: "14px",
                                    background:
                                        "linear-gradient(135deg, #1071FF 0%, #0056CC 100%)",
                                    boxShadow:
                                        "0 10px 24px rgba(0, 66, 173, 0.24)",
                                    "&:hover": {
                                        background:
                                            "linear-gradient(135deg, #1A7AFF 0%, #004DB8 100%)",
                                        boxShadow:
                                            "0 12px 28px rgba(0, 66, 173, 0.28)",
                                    },
                                }}
                            >
                                {t("addEmail")}
                            </Button>
                        )}
                    </Stack>
                </Stack>
            </SidebarDrawer>

            <Dialog
                open={addViewerOpen}
                onClose={handleCloseAddViewer}
                fullWidth
                maxWidth="xs"
            >
                <DialogTitle>{t("addEmail")}</DialogTitle>
                <DialogContent>
                    <Stack sx={{ gap: 2, py: 1 }}>
                        <TextField
                            type="email"
                            label={t("enterEmail")}
                            value={viewerEmail}
                            onChange={(event) => {
                                setViewerEmail(event.target.value);
                                setViewerEmailError(null);
                            }}
                            autoFocus
                            fullWidth
                            error={!!viewerEmailError}
                            helperText={viewerEmailError ?? " "}
                            onKeyDown={(event) => {
                                if (event.key === "Enter") {
                                    void handleAddViewer();
                                }
                            }}
                        />
                        <Stack direction="row" sx={{ gap: 1 }}>
                            <Button
                                fullWidth
                                color="secondary"
                                onClick={handleCloseAddViewer}
                                disabled={isSubmittingViewer}
                            >
                                {t("cancel")}
                            </Button>
                            <Button
                                fullWidth
                                variant="contained"
                                onClick={() => void handleAddViewer()}
                                disabled={isSubmittingViewer}
                            >
                                {isSubmittingViewer
                                    ? t("sharing")
                                    : t("addEmail")}
                            </Button>
                        </Stack>
                    </Stack>
                </DialogContent>
            </Dialog>
        </>
    );
};

const ParticipantRow: React.FC<{
    participant: LockerCollectionParticipant;
    subtitle?: string;
    action?: React.ReactNode;
}> = ({ participant, subtitle, action }) => {
    const email = participant.email ?? t("unknownEmail");
    const avatarLetter = email.charAt(0).toUpperCase() || "?";

    return (
        <Stack
            direction="row"
            sx={{
                alignItems: "center",
                gap: 1.5,
                px: 1.5,
                py: 1.25,
                minHeight: 64,
            }}
        >
            <Avatar
                sx={(theme) => ({
                    width: 36,
                    height: 36,
                    fontSize: 16,
                    bgcolor: theme.vars.palette.fill.faintHover,
                    color: "text.base",
                })}
            >
                {avatarLetter}
            </Avatar>
            <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography variant="body" sx={{ fontWeight: "medium" }} noWrap>
                    {email}
                </Typography>
                {subtitle && (
                    <Typography
                        variant="small"
                        sx={{ color: "text.muted", mt: 0.25 }}
                        noWrap
                    >
                        {subtitle}
                    </Typography>
                )}
            </Box>
            {action}
        </Stack>
    );
};
