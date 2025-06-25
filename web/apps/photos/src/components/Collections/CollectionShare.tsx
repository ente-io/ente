import AddIcon from "@mui/icons-material/Add";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import BlockIcon from "@mui/icons-material/Block";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ContentCopyIcon from "@mui/icons-material/ContentCopyOutlined";
import DoneIcon from "@mui/icons-material/Done";
import DownloadSharpIcon from "@mui/icons-material/DownloadSharp";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import LinkIcon from "@mui/icons-material/Link";
import ModeEditIcon from "@mui/icons-material/ModeEdit";
import Photo, { default as PhotoIcon } from "@mui/icons-material/Photo";
import PublicIcon from "@mui/icons-material/Public";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import WorkspacesIcon from "@mui/icons-material/Workspaces";
import { Dialog, Stack, styled, Typography } from "@mui/material";
import NumberAvatar from "@mui/material/Avatar";
import TextField from "@mui/material/TextField";
import Avatar from "components/pages/gallery/Avatar";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import {
    SidebarDrawer,
    SidebarDrawerTitlebar,
    TitledNestedSidebarDrawer,
} from "ente-base/components/mui/SidebarDrawer";
import {
    RowButton,
    RowButtonDivider,
    RowButtonEndActivityIndicator,
    RowButtonGroup,
    RowButtonGroupHint,
    RowButtonGroupTitle,
    RowLabel,
    RowSwitch,
} from "ente-base/components/RowButton";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { useClipboardCopy } from "ente-base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { deriveInteractiveKey } from "ente-base/crypto";
import { isHTTPErrorWithStatus } from "ente-base/http";
import { formattedDateTime } from "ente-base/i18n-date";
import log from "ente-base/log";
import { appendCollectionKeyToShareURL } from "ente-gallery/services/share";
import type {
    Collection,
    CollectionNewParticipantRole,
    PublicURL,
} from "ente-media/collection";
import { type CollectionUser } from "ente-media/collection";
import { PublicLinkCreated } from "ente-new/photos/components/share/PublicLinkCreated";
import { avatarTextColor } from "ente-new/photos/services/avatar";
import {
    createPublicURL,
    deleteShareURL,
    shareCollection,
    unshareCollection,
    updatePublicURL,
    type CreatePublicURLAttributes,
    type UpdatePublicURLAttributes,
} from "ente-new/photos/services/collection";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { CustomError, parseSharingErrorCodes } from "ente-shared/error";
import { wait } from "ente-utils/promise";
import { useFormik } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, {
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { Trans } from "react-i18next";
import { z } from "zod/v4";

type CollectionShareProps = ModalVisibilityProps & {
    collection: Collection;
    collectionSummary: CollectionSummary;
};

export const CollectionShare: React.FC<CollectionShareProps> = ({
    open,
    onClose,
    collection,
    collectionSummary,
}) => {
    const { onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { syncWithRemote } = useContext(GalleryContext);

    // TODO: Duplicated from CollectionHeader.tsx
    /**
     * Return a new function by wrapping an async function in an error handler,
     * showing the global loading bar when the function runs, and syncing with
     * remote on completion.
     */
    const wrap = useCallback(
        (f: () => Promise<void>) => {
            const wrapped = async () => {
                showLoadingBar();
                try {
                    await f();
                } catch (e) {
                    onGenericError(e);
                } finally {
                    void syncWithRemote(false, true);
                    hideLoadingBar();
                }
            };
            return (): void => void wrapped();
        },
        [showLoadingBar, hideLoadingBar, onGenericError, syncWithRemote],
    );

    if (!collection || !collectionSummary) {
        return <></>;
    }

    const { type } = collectionSummary;

    return (
        <SidebarDrawer anchor="right" {...{ open, onClose }}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={onClose}
                    title={
                        type == "incomingShareCollaborator" ||
                        type == "incomingShareViewer"
                            ? t("sharing_details")
                            : t("share_album")
                    }
                    caption={collection.name}
                />
                <Stack sx={{ py: "20px", px: "8px", gap: "24px" }}>
                    {type == "incomingShareCollaborator" ||
                    type == "incomingShareViewer" ? (
                        <SharingDetails {...{ collection, type }} />
                    ) : (
                        <>
                            <EmailShare
                                onRootClose={onClose}
                                {...{ wrap, collection }}
                            />
                            <PublicShare
                                onRootClose={onClose}
                                {...{ collection }}
                            />
                        </>
                    )}
                </Stack>
            </Stack>
        </SidebarDrawer>
    );
};

function SharingDetails({ collection, type }) {
    const galleryContext = useContext(GalleryContext);

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user?.email
            : collection.owner?.email;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role == "COLLABORATOR")
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role == "VIEWER")
            .map((sharee) => sharee.email) || [];

    const isOwner = galleryContext.user?.id === collection.owner?.id;

    const isMe = (email: string) => email === galleryContext.user?.email;

    return (
        <>
            <Stack>
                <RowButtonGroupTitle icon={<AdminPanelSettingsIcon />}>
                    {t("owner")}
                </RowButtonGroupTitle>
                <RowButtonGroup>
                    <RowLabel
                        startIcon={<Avatar email={ownerEmail} />}
                        label={isOwner ? t("you") : ownerEmail}
                    />
                </RowButtonGroup>
            </Stack>
            {type == "incomingShareCollaborator" &&
                collaborators?.length > 0 && (
                    <Stack>
                        <RowButtonGroupTitle icon={<ModeEditIcon />}>
                            {t("collaborators")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            {collaborators.map((item, index) => (
                                <>
                                    <RowLabel
                                        key={item}
                                        startIcon={<Avatar email={item} />}
                                        label={isMe(item) ? t("you") : item}
                                    />
                                    {index !== collaborators.length - 1 && (
                                        <RowButtonDivider />
                                    )}
                                </>
                            ))}
                        </RowButtonGroup>
                    </Stack>
                )}
            {viewers?.length > 0 && (
                <Stack>
                    <RowButtonGroupTitle icon={<Photo />}>
                        {t("viewers")}
                    </RowButtonGroupTitle>
                    <RowButtonGroup>
                        {viewers.map((item, index) => (
                            <React.Fragment key={item}>
                                <RowLabel
                                    label={isMe(item) ? t("you") : item}
                                    startIcon={<Avatar email={item} />}
                                />
                                {index !== viewers.length - 1 && (
                                    <RowButtonDivider />
                                )}
                            </React.Fragment>
                        ))}
                    </RowButtonGroup>
                </Stack>
            )}
        </>
    );
}

const handleSharingErrors = (error) => {
    const parsedError = parseSharingErrorCodes(error);
    let errorMessage = "";
    switch (parsedError.message) {
        case CustomError.BAD_REQUEST:
            errorMessage = t("sharing_album_not_allowed");
            break;
        case CustomError.SUBSCRIPTION_NEEDED:
            errorMessage = t("sharing_disabled_for_free_accounts");
            break;
        case CustomError.NOT_FOUND:
            errorMessage = t("sharing_user_does_not_exist");
            break;
        default:
            errorMessage = `${t("generic_error_retry")} ${parsedError.message}`;
    }
    return errorMessage;
};

interface EmailShareProps {
    onRootClose: () => void;
    wrap: (f: () => Promise<void>) => () => void;
    collection: Collection;
}

const EmailShare: React.FC<EmailShareProps> = ({
    onRootClose,
    wrap,
    collection,
}) => {
    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageEmailShareView, setManageEmailShareView] = useState(false);
    const [participantRole, setParticipantRole] = useState<
        CollectionNewParticipantRole | undefined
    >(undefined);

    const closeAddParticipant = () => setAddParticipantView(false);

    const closeManageEmailShare = () => setManageEmailShareView(false);
    const openManageEmailShare = () => setManageEmailShareView(true);

    const openAddViewer = () => {
        setParticipantRole("VIEWER");
        setAddParticipantView(true);
    };

    const openAddCollaborator = () => {
        setParticipantRole("COLLABORATOR");
        setAddParticipantView(true);
    };

    return (
        <>
            <Stack>
                <RowButtonGroupTitle icon={<WorkspacesIcon />}>
                    {t("shared_with_people_count", {
                        count: collection.sharees?.length ?? 0,
                    })}
                </RowButtonGroupTitle>
                <RowButtonGroup>
                    {collection.sharees.length > 0 ? (
                        <>
                            <RowButton
                                fontWeight="regular"
                                startIcon={
                                    <AvatarGroup sharees={collection.sharees} />
                                }
                                label={
                                    collection.sharees.length === 1
                                        ? collection.sharees[0]?.email
                                        : null
                                }
                                endIcon={<ChevronRightIcon />}
                                onClick={openManageEmailShare}
                            />
                            <RowButtonDivider />
                        </>
                    ) : null}
                    <RowButton
                        startIcon={<AddIcon />}
                        onClick={openAddViewer}
                        label={t("add_viewers")}
                    />
                    <RowButtonDivider />
                    <RowButton
                        startIcon={<AddIcon />}
                        onClick={openAddCollaborator}
                        label={t("add_collaborators")}
                    />
                </RowButtonGroup>
            </Stack>
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                role={participantRole}
            />
            <ManageEmailShare
                open={manageEmailShareView}
                onClose={closeManageEmailShare}
                onRootClose={onRootClose}
                {...{ onRootClose, wrap, collection }}
                peopleCount={collection.sharees.length}
            />
        </>
    );
};

const AvatarContainer = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    marginLeft: -5,
});

const AvatarContainerOuter = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    marginLeft: 8,
});

const AvatarCounter = styled(NumberAvatar)({
    height: 20,
    width: 20,
    fontSize: 10,
    color: avatarTextColor,
});

const SHAREE_AVATAR_LIMIT = 6;

const AvatarGroup = ({ sharees }: { sharees: Collection["sharees"] }) => {
    const hasShareesOverLimit = sharees?.length > SHAREE_AVATAR_LIMIT;
    const countOfShareesOverLimit = sharees?.length - SHAREE_AVATAR_LIMIT;

    return (
        <AvatarContainerOuter>
            {sharees?.slice(0, 6).map((sharee) => (
                <AvatarContainer key={sharee.email}>
                    <Avatar
                        key={sharee.email}
                        email={sharee.email}
                        opacity={100}
                    />
                </AvatarContainer>
            ))}
            {hasShareesOverLimit && (
                <AvatarContainer key="extra-count">
                    <AvatarCounter>+{countOfShareesOverLimit}</AvatarCounter>
                </AvatarContainer>
            )}
        </AvatarContainerOuter>
    );
};

interface AddParticipantProps {
    collection: Collection;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    role: CollectionNewParticipantRole;
}

const AddParticipant: React.FC<AddParticipantProps> = ({
    open,
    collection,
    onClose,
    onRootClose,
    role,
}) => {
    const { user, syncWithRemote, emailList } = useContext(GalleryContext);

    const eligibleEmails = useMemo(
        () =>
            emailList.filter(
                (email) =>
                    email != user.email &&
                    !collection?.sharees?.find((value) => value.email == email),
            ),
        [emailList, collection.sharees],
    );

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const title = role == "VIEWER" ? t("add_viewers") : t("add_collaborators");

    const collectionShare: AddParticipantFormProps["onSubmit"] = async (
        emailOrEmails,
        setEmailFieldError,
    ) => {
        let emails: string[];
        if (typeof emailOrEmails == "string") {
            // If email is a string, it means the user entered a custom email
            // string, so validate it to skip self sharing and duplicate share.
            const email = emailOrEmails;
            if (email == user.email) {
                setEmailFieldError(t("sharing_with_self"));
                return;
            } else if (
                collection?.sharees?.find((value) => value.email === email)
            ) {
                setEmailFieldError(
                    t("sharing_already_shared", { email: email }),
                );
                return;
            }
            emails = [email];
        } else {
            emails = emailOrEmails;
        }

        for (const email of emails) {
            try {
                await shareCollection(collection, email, role);
            } catch (e) {
                if (isHTTPErrorWithStatus(e, 402)) {
                    setEmailFieldError(t("sharing_disabled_for_free_accounts"));
                    return;
                }

                if (isHTTPErrorWithStatus(e, 404)) {
                    setEmailFieldError(t("sharing_user_does_not_exist"));
                    return;
                }

                throw e;
            }
        }

        if (emails.length) {
            await syncWithRemote(false, true);
        }

        onClose();
    };

    return (
        <TitledNestedSidebarDrawer
            anchor="right"
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={title}
            caption={collection.name}
        >
            <AddParticipantForm
                existingEmails={eligibleEmails}
                submitButtonTitle={title}
                onSubmit={collectionShare}
            />
        </TitledNestedSidebarDrawer>
    );
};

interface AddParticipantFormProps {
    /**
     * Title for the submit button.
     */
    submitButtonTitle: string;
    /**
     * A list of emails the user can user to pick from.
     */
    existingEmails: string[];
    /**
     * Submission handler. A callback invoked when the submit button is pressed.
     *
     * @param emailOrEmail Either the new email that the user entered, or the
     * subset of {@link existingEmails} selected by the user.
     *
     * @param setEmailFieldError A function that can be called to set the error
     * message shown below the email input field.
     */
    onSubmit: (
        emailOrEmails: string | string[],
        setEmailFieldError: (message: string) => void,
    ) => Promise<void>;
}

const AddParticipantForm: React.FC<AddParticipantFormProps> = ({
    existingEmails,
    submitButtonTitle,
    onSubmit,
}) => {
    const formik = useFormik({
        initialValues: { email: "", selectedEmails: [] },
        onSubmit: async ({ email, selectedEmails }, { setFieldError }) => {
            const setEmailFieldError = (message: string) =>
                setFieldError("email", message);
            try {
                if (email) {
                    if (!z.email().safeParse(email).success) {
                        setEmailFieldError(t("invalid_email_error"));
                        return;
                    }

                    await onSubmit(email, setEmailFieldError);
                } else {
                    await onSubmit(selectedEmails, setEmailFieldError);
                }
            } catch (e) {
                log.error("Could not add participant", e);
                setEmailFieldError(t("generic_error"));
            }
        },
    });

    const resetExistingSelection = () =>
        formik.setFieldValue("selectedEmails", []);

    return (
        <form onSubmit={formik.handleSubmit}>
            <Stack sx={{ gap: 1, py: "20px", px: 2 }}>
                <div>
                    <RowButtonGroupTitle>
                        {t("add_new_email")}
                    </RowButtonGroupTitle>
                    <TextField
                        name="email"
                        type="email"
                        label={t("enter_email")}
                        margin="none"
                        value={formik.values.email}
                        onChange={formik.handleChange}
                        error={!!formik.errors.email}
                        helperText={formik.errors.email ?? " "}
                        disabled={formik.isSubmitting}
                        onClick={resetExistingSelection}
                        fullWidth
                    />
                </div>

                {existingEmails.length > 0 && (
                    <div>
                        <RowButtonGroupTitle>
                            {t("or_add_existing")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            {existingEmails.map((email, index) => (
                                <React.Fragment key={email}>
                                    <RowButton
                                        fontWeight="regular"
                                        onClick={() => {
                                            const emails =
                                                formik.values.selectedEmails;
                                            formik.setFieldValue(
                                                "selectedEmails",
                                                emails.includes(email)
                                                    ? emails.filter(
                                                          (e) => e != email,
                                                      )
                                                    : emails.concat(email),
                                            );
                                        }}
                                        label={email}
                                        startIcon={<Avatar email={email} />}
                                        endIcon={
                                            formik.values.selectedEmails.includes(
                                                email,
                                            ) ? (
                                                <DoneIcon />
                                            ) : null
                                        }
                                    />
                                    {index != existingEmails.length - 1 && (
                                        <RowButtonDivider />
                                    )}
                                </React.Fragment>
                            ))}
                        </RowButtonGroup>
                    </div>
                )}
                <LoadingButton
                    type="submit"
                    color="accent"
                    loading={formik.isSubmitting}
                    fullWidth
                    sx={{ my: 6 }}
                >
                    {submitButtonTitle}
                </LoadingButton>
            </Stack>
        </form>
    );
};

interface ManageEmailShareProps {
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    wrap: (f: () => Promise<void>) => () => void;
    collection: Collection;
    peopleCount: number;
}

const ManageEmailShare: React.FC<ManageEmailShareProps> = ({
    open,
    onClose,
    onRootClose,
    wrap,
    collection,
    peopleCount,
}) => {
    const galleryContext = useContext(GalleryContext);

    const { show: showAddParticipant, props: addParticipantVisibilityProps } =
        useModalVisibility();
    const {
        show: showManageParticipant,
        props: manageParticipantVisibilityProps,
    } = useModalVisibility();

    const participantType = useRef<"COLLABORATOR" | "VIEWER">(null);

    const selectedParticipant = useRef<CollectionUser>(null);

    const openAddCollab = () => {
        participantType.current = "COLLABORATOR";
        showAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = "VIEWER";
        showAddParticipant();
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user.email
            : collection.owner?.email;

    const isOwner = galleryContext.user.id === collection.owner?.id;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role == "COLLABORATOR")
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role == "VIEWER")
            .map((sharee) => sharee.email) || [];

    const openManageParticipant = (email) => {
        selectedParticipant.current = collection.sharees.find(
            (sharee) => sharee.email === email,
        );
        showManageParticipant();
    };

    return (
        <>
            <TitledNestedSidebarDrawer
                anchor="right"
                {...{ open, onClose }}
                onRootClose={handleRootClose}
                title={collection.name}
                caption={t("participants_count", { count: peopleCount })}
            >
                <Stack sx={{ gap: 3, py: "20px", px: "12px" }}>
                    <Stack>
                        <RowButtonGroupTitle icon={<AdminPanelSettingsIcon />}>
                            {t("owner")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            <RowLabel
                                startIcon={<Avatar email={ownerEmail} />}
                                label={isOwner ? t("you") : ownerEmail}
                            />
                        </RowButtonGroup>
                    </Stack>
                    <Stack>
                        <RowButtonGroupTitle icon={<ModeEditIcon />}>
                            {t("collaborators")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            {collaborators.map((item) => (
                                <React.Fragment key={item}>
                                    <RowButton
                                        fontWeight="regular"
                                        onClick={() =>
                                            openManageParticipant(item)
                                        }
                                        label={item}
                                        startIcon={<Avatar email={item} />}
                                        endIcon={<ChevronRightIcon />}
                                    />
                                    <RowButtonDivider />
                                </React.Fragment>
                            ))}

                            <RowButton
                                startIcon={<AddIcon />}
                                onClick={openAddCollab}
                                label={
                                    collaborators?.length
                                        ? t("add_more")
                                        : t("add_collaborators")
                                }
                            />
                        </RowButtonGroup>
                    </Stack>
                    <Stack>
                        <RowButtonGroupTitle icon={<Photo />}>
                            {t("viewers")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            {viewers.map((item) => (
                                <React.Fragment key={item}>
                                    <RowButton
                                        fontWeight="regular"
                                        onClick={() =>
                                            openManageParticipant(item)
                                        }
                                        label={item}
                                        startIcon={<Avatar email={item} />}
                                        endIcon={<ChevronRightIcon />}
                                    />
                                    <RowButtonDivider />
                                </React.Fragment>
                            ))}
                            <RowButton
                                startIcon={<AddIcon />}
                                onClick={openAddViewer}
                                label={
                                    viewers?.length
                                        ? t("add_more")
                                        : t("add_viewers")
                                }
                            />
                        </RowButtonGroup>
                    </Stack>
                </Stack>
            </TitledNestedSidebarDrawer>
            <AddParticipant
                {...addParticipantVisibilityProps}
                onRootClose={onRootClose}
                collection={collection}
                role={participantType.current}
            />
            <ManageParticipant
                {...manageParticipantVisibilityProps}
                {...{ onRootClose, wrap, collection }}
                selectedParticipant={selectedParticipant.current}
            />
        </>
    );
};

interface ManageParticipantProps {
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    wrap: (f: () => Promise<void>) => () => void;
    collection: Collection;
    selectedParticipant: CollectionUser;
}

const ManageParticipant: React.FC<ManageParticipantProps> = ({
    open,
    onClose,
    onRootClose,
    wrap,
    collection,
    selectedParticipant,
}) => {
    const { showMiniDialog } = useBaseContext();
    const galleryContext = useContext(GalleryContext);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const unshare = wrap(() =>
        unshareCollection(collection.id, selectedParticipant.email),
    );

    const handleRemove = () => {
        unshare();
        onClose();
    };

    const handleRoleChange = (role: string) => () => {
        if (role !== selectedParticipant.role) {
            changeRolePermission(selectedParticipant.email, role);
        }
    };

    const updateCollectionRole = async (selectedEmail, newRole) => {
        try {
            await shareCollection(collection, selectedEmail, newRole);
            selectedParticipant.role = newRole;
            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            log.error(handleSharingErrors(e), e);
        }
    };

    const changeRolePermission = (selectedEmail, newRole) => {
        let contentText;
        let buttonText;

        if (newRole == "VIEWER") {
            contentText = (
                <Trans
                    i18nKey="change_permission_to_viewer"
                    values={{ selectedEmail }}
                />
            );

            buttonText = t("confirm_convert_to_viewer");
        } else if (newRole == "COLLABORATOR") {
            contentText = t("change_permission_to_collaborator", {
                selectedEmail,
            });
            buttonText = t("confirm_convert_to_collaborator");
        }

        showMiniDialog({
            title: t("change_permission_title"),
            message: contentText,
            continue: {
                text: buttonText,
                color: "critical",
                action: () => updateCollectionRole(selectedEmail, newRole),
            },
        });
    };

    const removeParticipant = () => {
        showMiniDialog({
            title: t("remove_participant_title"),
            message: (
                <Trans
                    i18nKey="remove_participant_message"
                    values={{ selectedEmail: selectedParticipant.email }}
                />
            ),
            continue: {
                text: t("confirm_remove"),
                color: "critical",
                action: handleRemove,
            },
        });
    };

    if (!selectedParticipant) {
        return <></>;
    }

    return (
        <TitledNestedSidebarDrawer
            anchor="right"
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("manage")}
            caption={selectedParticipant.email}
        >
            <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                <Stack>
                    <Typography
                        variant="small"
                        sx={{ color: "text.muted", padding: 1 }}
                    >
                        {t("added_as")}
                    </Typography>

                    <RowButtonGroup>
                        <RowButton
                            fontWeight="regular"
                            onClick={handleRoleChange("COLLABORATOR")}
                            label={"Collaborator"}
                            startIcon={<ModeEditIcon />}
                            endIcon={
                                selectedParticipant.role === "COLLABORATOR" && (
                                    <DoneIcon />
                                )
                            }
                        />
                        <RowButtonDivider />

                        <RowButton
                            fontWeight="regular"
                            onClick={handleRoleChange("VIEWER")}
                            label={"Viewer"}
                            startIcon={<PhotoIcon />}
                            endIcon={
                                selectedParticipant.role == "VIEWER" && (
                                    <DoneIcon />
                                )
                            }
                        />
                    </RowButtonGroup>

                    <Typography
                        variant="small"
                        sx={{ color: "text.muted", padding: 1 }}
                    >
                        {t("collaborator_hint")}
                    </Typography>

                    <Stack sx={{ py: "30px" }}>
                        <Typography
                            variant="small"
                            sx={{ color: "text.muted", padding: 1 }}
                        >
                            {t("remove_participant")}
                        </Typography>

                        <RowButtonGroup>
                            <RowButton
                                color="critical"
                                fontWeight="regular"
                                onClick={removeParticipant}
                                label={"Remove"}
                                startIcon={<BlockIcon />}
                            />
                        </RowButtonGroup>
                    </Stack>
                </Stack>
            </Stack>
        </TitledNestedSidebarDrawer>
    );
};

interface PublicShareProps {
    collection: Collection;
    onRootClose: () => void;
}

const PublicShare: React.FC<PublicShareProps> = ({
    collection,
    onRootClose,
}) => {
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicURL, setPublicURL] = useState<PublicURL | undefined>(
        undefined,
    );
    const {
        show: showPublicLinkCreated,
        props: publicLinkCreatedVisibilityProps,
    } = useModalVisibility();

    useEffect(() => {
        setPublicURL(collection.publicURLs[0]);
    }, [collection]);

    useEffect(() => {
        if (publicURL?.url) {
            appendCollectionKeyToShareURL(publicURL.url, collection.key).then(
                (url) => setPublicShareUrl(url),
            );
        } else {
            setPublicShareUrl(null);
        }
    }, [publicURL]);

    const handleCopyLink = () => {
        navigator.clipboard.writeText(publicShareUrl);
    };

    return (
        <>
            {publicURL ? (
                <ManagePublicShare
                    {...{ onRootClose, collection, publicURL, setPublicURL }}
                    publicShareUrl={publicShareUrl}
                />
            ) : (
                <EnablePublicShareOptions
                    {...{ setPublicURL }}
                    collection={collection}
                    onLinkCreated={showPublicLinkCreated}
                />
            )}
            <PublicLinkCreated
                {...publicLinkCreatedVisibilityProps}
                onCopyLink={handleCopyLink}
            />
        </>
    );
};

interface EnablePublicShareOptionsProps {
    collection: Collection;
    setPublicURL: (value: PublicURL) => void;
    onLinkCreated: () => void;
}

const EnablePublicShareOptions: React.FC<EnablePublicShareOptionsProps> = ({
    collection,
    setPublicURL,
    onLinkCreated,
}) => {
    const { syncWithRemote } = useContext(GalleryContext);

    const [pending, setPending] = useState("");
    const [errorMessage, setErrorMessage] = useState("");

    const create = (attributes?: CreatePublicURLAttributes) => {
        setErrorMessage("");
        setPending(attributes ? "collect" : "link");

        void createPublicURL(collection.id, attributes)
            .then((publicURL) => {
                setPending("");
                setPublicURL(publicURL);
                onLinkCreated();
                void syncWithRemote(false, true);
            })
            .catch((e: unknown) => {
                log.error("Could not create public link", e);
                setErrorMessage(
                    isHTTPErrorWithStatus(e, 402)
                        ? t("sharing_disabled_for_free_accounts")
                        : t("generic_error"),
                );
                setPending("");
            });
    };

    return (
        <Stack>
            <RowButtonGroupTitle icon={<PublicIcon />}>
                {t("share_link_section_title")}
            </RowButtonGroupTitle>
            <RowButtonGroup>
                <RowButton
                    label={t("create_public_link")}
                    startIcon={<LinkIcon />}
                    disabled={!!pending}
                    endIcon={
                        pending == "link" && <RowButtonEndActivityIndicator />
                    }
                    onClick={() => create()}
                />
                <RowButtonDivider />
                <RowButton
                    label={t("collect_photos")}
                    startIcon={<DownloadSharpIcon />}
                    disabled={!!pending}
                    endIcon={
                        pending == "collect" && (
                            <RowButtonEndActivityIndicator />
                        )
                    }
                    onClick={() => create({ enableCollect: true })}
                />
            </RowButtonGroup>
            {errorMessage && (
                <Typography
                    variant="small"
                    sx={{
                        color: "critical.main",
                        mt: 0.5,
                        textAlign: "center",
                    }}
                >
                    {errorMessage}
                </Typography>
            )}
        </Stack>
    );
};

interface ManagePublicShareProps {
    onRootClose: () => void;
    collection: Collection;
    publicURL: PublicURL;
    setPublicURL: (publicURL: PublicURL | undefined) => void;
    publicShareUrl: string;
}

const ManagePublicShare: React.FC<ManagePublicShareProps> = ({
    onRootClose,
    collection,
    publicURL,
    setPublicURL,
    publicShareUrl,
}) => {
    const {
        show: showManagePublicShare,
        props: managePublicShareVisibilityProps,
    } = useModalVisibility();

    const [copied, handleCopyLink] = useClipboardCopy(publicShareUrl);

    return (
        <>
            <Stack>
                <RowButtonGroupTitle icon={<PublicIcon />}>
                    {t("public_link_enabled")}
                </RowButtonGroupTitle>
                <RowButtonGroup>
                    {isLinkExpired(publicURL.validTill) ? (
                        <RowButton
                            disabled
                            startIcon={<ErrorOutlineIcon />}
                            color="critical"
                            onClick={showManagePublicShare}
                            label={t("link_expired")}
                        />
                    ) : (
                        <RowButton
                            startIcon={
                                copied ? (
                                    <DoneIcon sx={{ color: "accent.main" }} />
                                ) : (
                                    <ContentCopyIcon />
                                )
                            }
                            onClick={handleCopyLink}
                            disabled={isLinkExpired(publicURL.validTill)}
                            label={t("copy_link")}
                        />
                    )}
                    <RowButtonDivider />
                    <RowButton
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={showManagePublicShare}
                        label={t("manage_link")}
                    />
                </RowButtonGroup>
            </Stack>
            <ManagePublicShareOptions
                {...managePublicShareVisibilityProps}
                onRootClose={onRootClose}
                {...{ onRootClose, collection, publicURL, setPublicURL }}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
};

const isLinkExpired = (validTill: number) => {
    return validTill && validTill < Date.now() * 1000;
};

type ManagePublicShareOptionsProps = ModalVisibilityProps & {
    onRootClose: () => void;
    collection: Collection;
    publicURL: PublicURL;
    setPublicURL: (publicURL: PublicURL | undefined) => void;
    publicShareUrl: string;
};

const ManagePublicShareOptions: React.FC<ManagePublicShareOptionsProps> = ({
    open,
    onClose,
    onRootClose,
    collection,
    publicURL,
    setPublicURL,
    publicShareUrl,
}) => {
    const galleryContext = useContext(GalleryContext);

    const [sharableLinkError, setSharableLinkError] = useState(null);

    const [copied, handleCopyLink] = useClipboardCopy(publicShareUrl);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handlePublicURLUpdate = async (
        updates: UpdatePublicURLAttributes,
    ) => {
        try {
            galleryContext.setBlockingLoad(true);
            setPublicURL(await updatePublicURL(collection.id, updates));
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            log.error("Could not update public link", e);
            setSharableLinkError(t("generic_error"));
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const handleRemovePublicLink = async () => {
        try {
            galleryContext.setBlockingLoad(true);
            await deleteShareURL(collection.id);
            setPublicURL(undefined);
            galleryContext.syncWithRemote(false, true);
            onClose();
        } catch (e) {
            log.error("Failed to remove public link", e);
            setSharableLinkError(t("generic_error"));
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    return (
        <TitledNestedSidebarDrawer
            anchor="right"
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("share_album")}
        >
            <Stack sx={{ gap: 3, py: "20px", px: "8px" }}>
                <ManagePublicCollect
                    {...{ publicURL }}
                    onUpdate={handlePublicURLUpdate}
                />
                <ManageLinkExpiry
                    {...{ onRootClose, publicURL }}
                    onUpdate={handlePublicURLUpdate}
                />
                <RowButtonGroup>
                    <ManageDeviceLimit
                        {...{ onRootClose, publicURL }}
                        onUpdate={handlePublicURLUpdate}
                    />
                    <RowButtonDivider />
                    <ManageDownloadAccess
                        {...{ publicURL }}
                        onUpdate={handlePublicURLUpdate}
                    />
                    <RowButtonDivider />
                    <ManageLinkPassword
                        {...{ publicURL }}
                        onUpdate={handlePublicURLUpdate}
                    />
                </RowButtonGroup>
                <RowButtonGroup>
                    <RowButton
                        startIcon={
                            copied ? (
                                <DoneIcon sx={{ color: "accent.main" }} />
                            ) : (
                                <ContentCopyIcon />
                            )
                        }
                        onClick={handleCopyLink}
                        label={t("copy_link")}
                    />
                </RowButtonGroup>
                <RowButtonGroup>
                    <RowButton
                        color="critical"
                        startIcon={<RemoveCircleOutlineIcon />}
                        onClick={handleRemovePublicLink}
                        label={t("remove_link")}
                    />
                </RowButtonGroup>
                {sharableLinkError && (
                    <Typography
                        variant="small"
                        sx={{ color: "critical.main", textAlign: "center" }}
                    >
                        {sharableLinkError}
                    </Typography>
                )}
            </Stack>
        </TitledNestedSidebarDrawer>
    );
};

/**
 * The Prop type used by components that allow the use to modify some setting
 * related to a public link.
 */
interface ManagePublicLinkSettingProps {
    publicURL: PublicURL;
    onUpdate: (req: UpdatePublicURLAttributes) => Promise<void>;
}

/**
 * An extension of {@link ManagePublicLinkSettingProps} for use when the
 * component shows update options in a (nested) drawer.
 */
type ManagePublicLinkSettingDrawerProps = ManagePublicLinkSettingProps & {
    onRootClose: () => void;
};

const ManagePublicCollect: React.FC<ManagePublicLinkSettingProps> = ({
    publicURL,
    onUpdate,
}) => {
    const handleFileDownloadSetting = () => {
        onUpdate({ enableCollect: !publicURL.enableCollect });
    };

    return (
        <Stack>
            <RowButtonGroup>
                <RowSwitch
                    label={t("allow_adding_photos")}
                    checked={publicURL.enableCollect}
                    onClick={handleFileDownloadSetting}
                />
            </RowButtonGroup>
            <RowButtonGroupHint>
                {t("allow_adding_photos_hint")}
            </RowButtonGroupHint>
        </Stack>
    );
};

const ManageLinkExpiry: React.FC<ManagePublicLinkSettingDrawerProps> = ({
    onRootClose,
    publicURL,
    onUpdate,
}) => {
    const { show: showExpiryOptions, props: expiryOptionsVisibilityProps } =
        useModalVisibility();

    const options = useMemo(() => shareExpiryOptions(), []);

    const changeShareExpiryValue = (value: number) => async () => {
        await onUpdate({ validTill: value });
        expiryOptionsVisibilityProps.onClose();
    };

    return (
        <>
            <RowButtonGroup>
                <RowButton
                    onClick={showExpiryOptions}
                    endIcon={<ChevronRightIcon />}
                    label={t("link_expiry")}
                    color={
                        isLinkExpired(publicURL.validTill)
                            ? "critical"
                            : "primary"
                    }
                    caption={
                        isLinkExpired(publicURL.validTill)
                            ? t("link_expired")
                            : publicURL.validTill
                              ? formattedDateTime(publicURL.validTill)
                              : t("never")
                    }
                />
            </RowButtonGroup>
            <TitledNestedSidebarDrawer
                anchor="right"
                {...expiryOptionsVisibilityProps}
                onRootClose={onRootClose}
                title={t("link_expiry")}
            >
                <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                    <RowButtonGroup>
                        {options.map(({ label, value }, index) => (
                            <React.Fragment key={value()}>
                                <RowButton
                                    fontWeight="regular"
                                    onClick={changeShareExpiryValue(value())}
                                    label={label}
                                />
                                {index != options.length - 1 && (
                                    <RowButtonDivider />
                                )}
                            </React.Fragment>
                        ))}
                    </RowButtonGroup>
                </Stack>
            </TitledNestedSidebarDrawer>
        </>
    );
};

const shareExpiryOptions = () => [
    { label: t("never"), value: () => 0 },
    { label: t("after_time.hour"), value: () => microsecsAfter("hour") },
    { label: t("after_time.day"), value: () => microsecsAfter("day") },
    { label: t("after_time.week"), value: () => microsecsAfter("week") },
    { label: t("after_time.month"), value: () => microsecsAfter("month") },
    { label: t("after_time.year"), value: () => microsecsAfter("year") },
];

const microsecsAfter = (after: "hour" | "day" | "week" | "month" | "year") => {
    let date = new Date();
    switch (after) {
        case "hour":
            date = new Date(date.getTime() + 60 * 60 * 1000);
            break;
        case "day":
            date.setDate(date.getDate() + 1);
            break;
        case "week":
            date.setDate(date.getDate() + 7);
            break;
        case "month":
            date.setMonth(date.getMonth() + 1);
            break;
        case "year":
            date.setFullYear(date.getFullYear() + 1);
            break;
    }
    return date.getTime() * 1000;
};

const ManageDeviceLimit: React.FC<ManagePublicLinkSettingDrawerProps> = ({
    onRootClose,
    publicURL,
    onUpdate,
}) => {
    const { show: showDeviceOptions, props: deviceOptionsVisibilityProps } =
        useModalVisibility();

    const options = useMemo(() => deviceLimitOptions(), []);

    const changeDeviceLimitValue = (value: number) => async () => {
        await onUpdate({ deviceLimit: value });
        deviceOptionsVisibilityProps.onClose();
    };

    return (
        <>
            <RowButton
                label={t("device_limit")}
                caption={
                    publicURL.deviceLimit == 0
                        ? t("none")
                        : publicURL.deviceLimit.toString()
                }
                onClick={showDeviceOptions}
                endIcon={<ChevronRightIcon />}
            />
            <TitledNestedSidebarDrawer
                anchor="right"
                {...deviceOptionsVisibilityProps}
                onRootClose={onRootClose}
                title={t("device_limit")}
            >
                <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                    <RowButtonGroup>
                        {options.map(({ label, value }, index) => (
                            <React.Fragment key={label}>
                                <RowButton
                                    fontWeight="regular"
                                    onClick={changeDeviceLimitValue(value)}
                                    label={label}
                                />
                                {index != options.length - 1 && (
                                    <RowButtonDivider />
                                )}
                            </React.Fragment>
                        ))}
                    </RowButtonGroup>
                </Stack>
            </TitledNestedSidebarDrawer>
        </>
    );
};

const deviceLimitOptions = () =>
    [0, 2, 5, 10, 25, 50].map((i) => ({
        label: i == 0 ? t("none") : i.toString(),
        value: i,
    }));

const ManageDownloadAccess: React.FC<ManagePublicLinkSettingProps> = ({
    publicURL,
    onUpdate,
}) => {
    const { showMiniDialog } = useBaseContext();

    const handleFileDownloadSetting = () => {
        if (publicURL.enableDownload) {
            showMiniDialog({
                title: t("disable_file_download"),
                message: <Trans i18nKey={"disable_file_download_message"} />,
                continue: {
                    text: t("disable"),
                    color: "critical",
                    action: () => onUpdate({ enableDownload: false }),
                },
            });
        } else {
            onUpdate({ enableDownload: true });
        }
    };

    return (
        <RowSwitch
            label={t("allow_downloads")}
            checked={publicURL.enableDownload}
            onClick={handleFileDownloadSetting}
        />
    );
};

const ManageLinkPassword: React.FC<ManagePublicLinkSettingProps> = ({
    publicURL,
    onUpdate,
}) => {
    const { showMiniDialog } = useBaseContext();
    const { show: showSetPassword, props: setPasswordVisibilityProps } =
        useModalVisibility();

    const handlePasswordChangeSetting = async () => {
        if (publicURL.passwordEnabled) {
            showMiniDialog({
                title: t("disable_password"),
                message: t("disable_password_message"),
                continue: {
                    text: t("disable"),
                    color: "critical",
                    action: () => onUpdate({ disablePassword: true }),
                },
            });
        } else {
            showSetPassword();
        }
    };

    return (
        <>
            <RowSwitch
                label={t("password_lock")}
                checked={publicURL.passwordEnabled}
                onClick={handlePasswordChangeSetting}
            />
            <SetPublicLinkPassword
                {...setPasswordVisibilityProps}
                {...{ publicURL, onUpdate }}
            />
        </>
    );
};

type SetPublicLinkPasswordProps = ModalVisibilityProps &
    ManagePublicLinkSettingProps;

const SetPublicLinkPassword: React.FC<SetPublicLinkPasswordProps> = ({
    open,
    onClose,
    publicURL,
    onUpdate,
}) => {
    const savePassword: SingleInputFormProps["onSubmit"] = async (password) => {
        await enablePublicUrlPassword(password);
        publicURL.passwordEnabled = true;
        onClose();
        // The onClose above will close the dialog, but if we return immediately
        // from this function, then the dialog will be temporarily rendered
        // without the activity indicator on the button (before the entire
        // dialog disappears). This gives a ungainly visual flash, so add a wait
        // long enough so that the form's activity indicator persists longer
        // than it'll take for the dialog to get closed.
        return wait(1000 /* 1 second */);
    };

    const enablePublicUrlPassword = async (password: string) => {
        const kek = await deriveInteractiveKey(password);
        return onUpdate({
            passHash: kek.key,
            nonce: kek.salt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };

    return (
        <Dialog
            {...{ open, onClose }}
            disablePortal
            slotProps={{
                // We're being shown within the sidebar drawer, so limit the
                // backdrop to only cover the drawer.
                backdrop: { sx: { position: "absolute" } },
                // We're being shown within the sidebar drawer, and also the
                // content of this dialog is lesser than what a normal dialog
                // contains. Use a bespoke padding.
                paper: { sx: { "&&": { padding: "4px" } } },
            }}
            sx={{ position: "absolute" }}
            maxWidth={"sm"}
            fullWidth
        >
            <Stack sx={{ gap: 3, p: 1.5 }}>
                <Typography variant="h3" sx={{ px: 1, py: 0.5 }}>
                    {t("password_lock")}
                </Typography>
                <SingleInputForm
                    inputType="password"
                    label={t("password")}
                    submitButtonColor="primary"
                    submitButtonTitle={t("lock")}
                    onCancel={onClose}
                    onSubmit={savePassword}
                />
            </Stack>
        </Dialog>
    );
};
