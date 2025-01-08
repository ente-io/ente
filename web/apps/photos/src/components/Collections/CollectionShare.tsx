import {
    MenuItemDivider,
    MenuItemGroup,
    MenuSectionTitle,
} from "@/base/components/Menu";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { useModalVisibility } from "@/base/components/utils/modal";
import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { appendCollectionKeyToShareURL } from "@/gallery/services/share";
import type {
    Collection,
    PublicURL,
    UpdatePublicURL,
} from "@/media/collection";
import { COLLECTION_ROLE, type CollectionUser } from "@/media/collection";
import { PublicLinkCreated } from "@/new/photos/components/share/PublicLinkCreated";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import { AppContext, useAppContext } from "@/new/photos/types/context";
import { FlexWrapper } from "@ente/shared/components/Container";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { CustomError, parseSharingErrorCodes } from "@ente/shared/error";
import { formatDateTime } from "@ente/shared/time/format";
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
import {
    Dialog,
    DialogProps,
    FormHelperText,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import NumberAvatar from "@mui/material/Avatar";
import TextField from "@mui/material/TextField";
import Avatar from "components/pages/gallery/Avatar";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import { Trans } from "react-i18next";
import {
    createShareableURL,
    deleteShareableURL,
    shareCollection,
    unshareCollection,
    updateShareableURL,
} from "services/collectionService";
import { getDeviceLimitOptions } from "utils/collection";
import * as Yup from "yup";

interface CollectionShareProps {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    collectionSummary: CollectionSummary;
}

export const CollectionShare: React.FC<CollectionShareProps> = ({
    collectionSummary,
    ...props
}) => {
    const handleRootClose = () => {
        props.onClose();
    };
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            handleRootClose();
        } else {
            props.onClose();
        }
    };
    if (!props.collection || !collectionSummary) {
        return <></>;
    }
    const { type } = collectionSummary;

    return (
        <SidebarDrawer
            anchor="right"
            open={props.open}
            onClose={handleDrawerClose}
            slotProps={{
                backdrop: {
                    sx: { "&&&": { backgroundColor: "transparent" } },
                },
            }}
        >
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <Titlebar
                    onClose={props.onClose}
                    title={
                        type == "incomingShareCollaborator" ||
                        type == "incomingShareViewer"
                            ? t("sharing_details")
                            : t("share_album")
                    }
                    onRootClose={handleRootClose}
                    caption={props.collection.name}
                />
                <Stack sx={{ py: "20px", px: "8px", gap: "24px" }}>
                    {type == "incomingShareCollaborator" ||
                    type == "incomingShareViewer" ? (
                        <SharingDetails
                            collection={props.collection}
                            type={type}
                        />
                    ) : (
                        <>
                            <EmailShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <PublicShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
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
        ?.filter((sharee) => sharee.role === COLLECTION_ROLE.COLLABORATOR)
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role === COLLECTION_ROLE.VIEWER)
            .map((sharee) => sharee.email) || [];

    const isOwner = galleryContext.user?.id === collection.owner?.id;

    const isMe = (email: string) => email === galleryContext.user?.email;

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t("OWNER")}
                    icon={<AdminPanelSettingsIcon />}
                />
                <MenuItemGroup>
                    <EnteMenuItem
                        fontWeight="normal"
                        onClick={() => {}}
                        label={isOwner ? t("you") : ownerEmail}
                        startIcon={<Avatar email={ownerEmail} />}
                    />
                </MenuItemGroup>
            </Stack>
            {type == "incomingShareCollaborator" &&
                collaborators?.length > 0 && (
                    <Stack>
                        <MenuSectionTitle
                            title={t("COLLABORATORS")}
                            icon={<ModeEditIcon />}
                        />
                        <MenuItemGroup>
                            {collaborators.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item}
                                        onClick={() => {}}
                                        label={isMe(item) ? t("you") : item}
                                        startIcon={<Avatar email={item} />}
                                    />
                                    {index !== collaborators.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                )}
            {viewers?.length > 0 && (
                <Stack>
                    <MenuSectionTitle title={t("VIEWERS")} icon={<Photo />} />
                    <MenuItemGroup>
                        {viewers.map((item, index) => (
                            <>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    key={item}
                                    onClick={() => {}}
                                    label={isMe(item) ? t("you") : item}
                                    startIcon={<Avatar email={item} />}
                                />
                                {index !== viewers.length - 1 && (
                                    <MenuItemDivider />
                                )}
                            </>
                        ))}
                    </MenuItemGroup>
                </Stack>
            )}
        </>
    );
}

type SetPublicShareProp = React.Dispatch<React.SetStateAction<PublicURL>>;

interface EnablePublicShareOptionsProps {
    collection: Collection;
    setPublicShareProp: (value: PublicURL) => void;
    onLinkCreated: () => void;
}

const EnablePublicShareOptions: React.FC<EnablePublicShareOptionsProps> = ({
    collection,
    setPublicShareProp,
    onLinkCreated,
}) => {
    const galleryContext = useContext(GalleryContext);
    const [sharableLinkError, setSharableLinkError] = useState(null);

    const createSharableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            setPublicShareProp(publicURL);
            onLinkCreated();
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    const createCollectPhotoShareableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            await updateShareableURL({
                collectionID: collection.id,
                enableCollect: true,
            });
            setPublicShareProp(publicURL);
            onLinkCreated();
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    return (
        <Stack>
            <MenuSectionTitle
                title={t("LINK_SHARE_TITLE")}
                icon={<PublicIcon />}
            />
            <MenuItemGroup>
                <EnteMenuItem
                    label={t("CREATE_PUBLIC_SHARING")}
                    startIcon={<LinkIcon />}
                    onClick={createSharableURLHelper}
                />
                <MenuItemDivider hasIcon />
                <EnteMenuItem
                    label={t("COLLECT_PHOTOS")}
                    startIcon={<DownloadSharpIcon />}
                    onClick={createCollectPhotoShareableURLHelper}
                />
            </MenuItemGroup>
            {sharableLinkError && (
                <Typography
                    variant="small"
                    sx={(theme) => ({
                        color: theme.colors.danger.A700,
                        mt: 0.5,
                        textAlign: "center",
                    })}
                >
                    {sharableLinkError}
                </Typography>
            )}
        </Stack>
    );
};

const handleSharingErrors = (error) => {
    const parsedError = parseSharingErrorCodes(error);
    let errorMessage = "";
    switch (parsedError.message) {
        case CustomError.BAD_REQUEST:
            errorMessage = t("SHARING_BAD_REQUEST_ERROR");
            break;
        case CustomError.SUBSCRIPTION_NEEDED:
            errorMessage = t("SHARING_DISABLED_FOR_FREE_ACCOUNTS");
            break;
        case CustomError.NOT_FOUND:
            errorMessage = t("USER_DOES_NOT_EXIST");
            break;
        default:
            errorMessage = `${t("generic_error_retry")} ${parsedError.message}`;
    }
    return errorMessage;
};

interface EmailShareProps {
    collection: Collection;
    onRootClose: () => void;
}

const EmailShare: React.FC<EmailShareProps> = ({ collection, onRootClose }) => {
    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageEmailShareView, setManageEmailShareView] = useState(false);

    const closeAddParticipant = () => setAddParticipantView(false);
    const openAddParticipant = () => setAddParticipantView(true);

    const closeManageEmailShare = () => setManageEmailShareView(false);
    const openManageEmailShare = () => setManageEmailShareView(true);

    const participantType = useRef<
        COLLECTION_ROLE.COLLABORATOR | COLLECTION_ROLE.VIEWER
    >(undefined);

    const openAddCollab = () => {
        participantType.current = COLLECTION_ROLE.COLLABORATOR;
        openAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = COLLECTION_ROLE.VIEWER;
        openAddParticipant();
    };

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t("shared_with_people_count", {
                        count: collection.sharees?.length ?? 0,
                    })}
                    icon={<WorkspacesIcon />}
                />
                <MenuItemGroup>
                    {collection.sharees.length > 0 ? (
                        <>
                            <EnteMenuItem
                                fontWeight={"normal"}
                                startIcon={
                                    <AvatarGroup sharees={collection.sharees} />
                                }
                                onClick={openManageEmailShare}
                                label={
                                    collection.sharees.length === 1
                                        ? collection.sharees[0]?.email
                                        : null
                                }
                                endIcon={<ChevronRightIcon />}
                            />
                            <MenuItemDivider hasIcon />
                        </>
                    ) : null}
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openAddViewer}
                        label={t("ADD_VIEWERS")}
                    />
                    <MenuItemDivider hasIcon />
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openAddCollab}
                        label={t("ADD_COLLABORATORS")}
                    />
                </MenuItemGroup>
            </Stack>
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                type={participantType.current}
            />
            <ManageEmailShare
                peopleCount={collection.sharees.length}
                open={manageEmailShareView}
                onClose={closeManageEmailShare}
                onRootClose={onRootClose}
                collection={collection}
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
    color: "#fff",
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
    type: COLLECTION_ROLE.VIEWER | COLLECTION_ROLE.COLLABORATOR;
}

const AddParticipant: React.FC<AddParticipantProps> = ({
    open,
    collection,
    onClose,
    onRootClose,
    type,
}) => {
    const { user, syncWithRemote, emailList } = useContext(GalleryContext);

    const nonSharedEmails = useMemo(
        () =>
            emailList.filter(
                (email) =>
                    !collection.sharees?.find((value) => value.email === email),
            ),
        [emailList, collection.sharees],
    );

    const collectionShare: AddParticipantFormProps["callback"] = async ({
        email,
        emails,
    }) => {
        // if email is provided, means user has custom entered email, so, will need to validate for self sharing
        // and already shared
        if (email) {
            if (email === user.email) {
                throw new Error(t("SHARE_WITH_SELF"));
            } else if (
                collection?.sharees?.find((value) => value.email === email)
            ) {
                throw new Error(t("ALREADY_SHARED", { email: email }));
            }
            // set emails to array of one email
            emails = [email];
        }
        for (const email of emails) {
            if (
                email === user.email ||
                collection?.sharees?.find((value) => value.email === email)
            ) {
                // can just skip this email
                continue;
            }
            try {
                await shareCollection(collection, email, type);
                await syncWithRemote(false, true);
            } catch (e) {
                const errorMessage = handleSharingErrors(e);
                throw new Error(errorMessage);
            }
        }
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };

    return (
        <SidebarDrawer anchor="right" open={open} onClose={handleDrawerClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <Titlebar
                    onClose={onClose}
                    title={
                        type === COLLECTION_ROLE.VIEWER
                            ? t("ADD_VIEWERS")
                            : t("ADD_COLLABORATORS")
                    }
                    onRootClose={handleRootClose}
                    caption={collection.name}
                />
                <AddParticipantForm
                    onClose={onClose}
                    callback={collectionShare}
                    optionsList={nonSharedEmails}
                    placeholder={t("enter_email")}
                    fieldType="email"
                    buttonText={
                        type === COLLECTION_ROLE.VIEWER
                            ? t("ADD_VIEWERS")
                            : t("ADD_COLLABORATORS")
                    }
                    submitButtonProps={{
                        size: "large",
                        sx: { mt: 1, mb: 2 },
                    }}
                    disableAutoFocus
                />
            </Stack>
        </SidebarDrawer>
    );
};

interface AddParticipantFormValues {
    inputValue: string;
    selectedOptions: string[];
}

interface AddParticipantFormProps {
    callback: (props: { email?: string; emails?: string[] }) => Promise<void>;
    fieldType: "text" | "email" | "password";
    placeholder: string;
    buttonText: string;
    submitButtonProps?: any;
    initialValue?: string;
    secondaryButtonAction?: () => void;
    disableAutoFocus?: boolean;
    hiddenPreInput?: any;
    caption?: any;
    hiddenPostInput?: any;
    autoComplete?: string;
    blockButton?: boolean;
    hiddenLabel?: boolean;
    onClose?: () => void;
    optionsList?: string[];
}

const AddParticipantForm: React.FC<AddParticipantFormProps> = (props) => {
    const { submitButtonProps } = props;
    const { sx: buttonSx, ...restSubmitButtonProps } = submitButtonProps ?? {};

    const [loading, SetLoading] = useState(false);

    const submitForm = async (
        values: AddParticipantFormValues,
        { setFieldError, resetForm }: FormikHelpers<AddParticipantFormValues>,
    ) => {
        try {
            SetLoading(true);
            if (values.inputValue !== "") {
                await props.callback({ email: values.inputValue });
            } else if (values.selectedOptions.length !== 0) {
                await props.callback({ emails: values.selectedOptions });
            }
            SetLoading(false);
            props.onClose();
            resetForm();
        } catch (e) {
            setFieldError("inputValue", e?.message);
            SetLoading(false);
        }
    };

    const validationSchema = useMemo(() => {
        switch (props.fieldType) {
            case "text":
                return Yup.object().shape({
                    inputValue: Yup.string().required(t("required")),
                });
            case "email":
                return Yup.object().shape({
                    inputValue: Yup.string().email(t("invalid_email_error")),
                });
        }
    }, [props.fieldType]);

    const handleInputFieldClick = (setFieldValue) => {
        setFieldValue("selectedOptions", []);
    };

    return (
        <Formik<AddParticipantFormValues>
            initialValues={{
                inputValue: props.initialValue ?? "",
                selectedOptions: [],
            }}
            onSubmit={submitForm}
            validationSchema={validationSchema}
            validateOnChange={false}
            validateOnBlur={false}
        >
            {({
                values,
                errors,
                handleChange,
                handleSubmit,
                setFieldValue,
            }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <Stack sx={{ gap: "24px", py: "20px", px: "12px" }}>
                        {props.hiddenPreInput}
                        <Stack>
                            <MenuSectionTitle title={t("ADD_NEW_EMAIL")} />
                            <TextField
                                sx={{ marginTop: 0 }}
                                hiddenLabel={props.hiddenLabel}
                                fullWidth
                                type={props.fieldType}
                                id={props.fieldType}
                                onChange={handleChange("inputValue")}
                                onClick={() =>
                                    handleInputFieldClick(setFieldValue)
                                }
                                name={props.fieldType}
                                {...(props.hiddenLabel
                                    ? { placeholder: props.placeholder }
                                    : { label: props.placeholder })}
                                error={Boolean(errors.inputValue)}
                                helperText={errors.inputValue}
                                value={values.inputValue}
                                disabled={loading}
                                autoFocus={!props.disableAutoFocus}
                                autoComplete={props.autoComplete}
                            />
                        </Stack>

                        {props.optionsList.length > 0 && (
                            <Stack>
                                <MenuSectionTitle
                                    title={t("OR_ADD_EXISTING")}
                                />
                                <MenuItemGroup>
                                    {props.optionsList.map((item, index) => (
                                        <>
                                            <EnteMenuItem
                                                fontWeight="normal"
                                                key={item}
                                                onClick={() => {
                                                    if (
                                                        values.selectedOptions.includes(
                                                            item,
                                                        )
                                                    ) {
                                                        setFieldValue(
                                                            "selectedOptions",
                                                            values.selectedOptions.filter(
                                                                (
                                                                    selectedOption,
                                                                ) =>
                                                                    selectedOption !==
                                                                    item,
                                                            ),
                                                        );
                                                    } else {
                                                        setFieldValue(
                                                            "selectedOptions",
                                                            [
                                                                ...values.selectedOptions,
                                                                item,
                                                            ],
                                                        );
                                                    }
                                                }}
                                                label={item}
                                                startIcon={
                                                    <Avatar email={item} />
                                                }
                                                endIcon={
                                                    values.selectedOptions.includes(
                                                        item,
                                                    ) ? (
                                                        <DoneIcon />
                                                    ) : null
                                                }
                                            />
                                            {index !==
                                                props.optionsList.length -
                                                    1 && <MenuItemDivider />}
                                        </>
                                    ))}
                                </MenuItemGroup>
                            </Stack>
                        )}

                        <FormHelperText
                            sx={{
                                position: "relative",
                                top: errors.inputValue ? "-22px" : "0",
                                float: "right",
                                padding: "0 8px",
                            }}
                        >
                            {props.caption}
                        </FormHelperText>
                        {props.hiddenPostInput}
                    </Stack>
                    <FlexWrapper
                        px={"8px"}
                        justifyContent={"center"}
                        flexWrap={props.blockButton ? "wrap-reverse" : "nowrap"}
                    >
                        <Stack sx={{ px: "8px", width: "100%" }}>
                            {props.secondaryButtonAction && (
                                <FocusVisibleButton
                                    onClick={props.secondaryButtonAction}
                                    fullWidth
                                    color="secondary"
                                    sx={{
                                        "&&&": {
                                            mt: !props.blockButton ? 2 : 0.5,
                                            mb: !props.blockButton ? 4 : 0,
                                            mr: !props.blockButton ? 1 : 0,
                                            ...buttonSx,
                                        },
                                    }}
                                    {...restSubmitButtonProps}
                                >
                                    {t("cancel")}
                                </FocusVisibleButton>
                            )}

                            <LoadingButton
                                type="submit"
                                color="accent"
                                fullWidth
                                buttonText={props.buttonText}
                                loading={loading}
                                sx={{ mt: 2, mb: 4 }}
                                {...restSubmitButtonProps}
                            >
                                {props.buttonText}
                            </LoadingButton>
                        </Stack>
                    </FlexWrapper>
                </form>
            )}
        </Formik>
    );
};

interface ManageEmailShareProps {
    collection: Collection;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    peopleCount: number;
}

const ManageEmailShare: React.FC<ManageEmailShareProps> = ({
    open,
    collection,
    onClose,
    onRootClose,
    peopleCount,
}) => {
    const { showLoadingBar, hideLoadingBar } = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageParticipantView, setManageParticipantView] = useState(false);

    const closeAddParticipant = () => setAddParticipantView(false);
    const openAddParticipant = () => setAddParticipantView(true);

    const participantType = useRef<
        COLLECTION_ROLE.COLLABORATOR | COLLECTION_ROLE.VIEWER
    >(null);

    const selectedParticipant = useRef<CollectionUser>(null);

    const openAddCollab = () => {
        participantType.current = COLLECTION_ROLE.COLLABORATOR;
        openAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = COLLECTION_ROLE.VIEWER;
        openAddParticipant();
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };

    const collectionUnshare = async (email: string) => {
        try {
            showLoadingBar();
            await unshareCollection(collection, email);
            await galleryContext.syncWithRemote(false, true);
        } finally {
            hideLoadingBar();
        }
    };

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user.email
            : collection.owner?.email;

    const isOwner = galleryContext.user.id === collection.owner?.id;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role === COLLECTION_ROLE.COLLABORATOR)
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role === COLLECTION_ROLE.VIEWER)
            .map((sharee) => sharee.email) || [];

    const openManageParticipant = (email) => {
        selectedParticipant.current = collection.sharees.find(
            (sharee) => sharee.email === email,
        );
        setManageParticipantView(true);
    };
    const closeManageParticipant = () => {
        setManageParticipantView(false);
    };

    return (
        <>
            <SidebarDrawer
                anchor="right"
                open={open}
                onClose={handleDrawerClose}
            >
                <Stack sx={{ gap: "4px", py: "12px" }}>
                    <Titlebar
                        onClose={onClose}
                        title={collection.name}
                        onRootClose={handleRootClose}
                        caption={t("participants_count", {
                            count: peopleCount,
                        })}
                    />
                    <Stack sx={{ gap: "24px", py: "20px", px: "12px" }}>
                        <Stack>
                            <MenuSectionTitle
                                title={t("OWNER")}
                                icon={<AdminPanelSettingsIcon />}
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    onClick={() => {}}
                                    label={isOwner ? t("you") : ownerEmail}
                                    startIcon={<Avatar email={ownerEmail} />}
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t("COLLABORATORS")}
                                icon={<ModeEditIcon />}
                            />
                            <MenuItemGroup>
                                {collaborators.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={"normal"}
                                            key={item}
                                            onClick={() =>
                                                openManageParticipant(item)
                                            }
                                            label={item}
                                            startIcon={<Avatar email={item} />}
                                            endIcon={<ChevronRightIcon />}
                                        />
                                        <MenuItemDivider hasIcon />
                                    </>
                                ))}

                                <EnteMenuItem
                                    startIcon={<AddIcon />}
                                    onClick={openAddCollab}
                                    label={
                                        collaborators?.length
                                            ? t("ADD_MORE")
                                            : t("ADD_COLLABORATORS")
                                    }
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t("VIEWERS")}
                                icon={<Photo />}
                            />
                            <MenuItemGroup>
                                {viewers.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={"normal"}
                                            key={item}
                                            onClick={() =>
                                                openManageParticipant(item)
                                            }
                                            label={item}
                                            startIcon={<Avatar email={item} />}
                                            endIcon={<ChevronRightIcon />}
                                        />

                                        <MenuItemDivider hasIcon />
                                    </>
                                ))}
                                <EnteMenuItem
                                    startIcon={<AddIcon />}
                                    fontWeight={"bold"}
                                    onClick={openAddViewer}
                                    label={
                                        viewers?.length
                                            ? t("ADD_MORE")
                                            : t("ADD_VIEWERS")
                                    }
                                />
                            </MenuItemGroup>
                        </Stack>
                    </Stack>
                </Stack>
            </SidebarDrawer>
            <ManageParticipant
                collectionUnshare={collectionUnshare}
                open={manageParticipantView}
                collection={collection}
                onRootClose={onRootClose}
                onClose={closeManageParticipant}
                selectedParticipant={selectedParticipant.current}
            />
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                type={participantType.current}
            />
        </>
    );
};

interface ManageParticipantProps {
    open: boolean;
    collection: Collection;
    onClose: () => void;
    onRootClose: () => void;
    selectedParticipant: CollectionUser;
    collectionUnshare: (email: string) => Promise<void>;
}

const ManageParticipant: React.FC<ManageParticipantProps> = ({
    collection,
    open,
    onClose,
    onRootClose,
    selectedParticipant,
    collectionUnshare,
}) => {
    const { showMiniDialog } = useAppContext();
    const galleryContext = useContext(GalleryContext);

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onRootClose();
        } else {
            onClose();
        }
    };

    const handleRemove = () => {
        collectionUnshare(selectedParticipant.email);
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

        if (newRole === "VIEWER") {
            contentText = (
                <Trans
                    i18nKey="CHANGE_PERMISSIONS_TO_VIEWER"
                    values={{
                        selectedEmail: `${selectedEmail}`,
                    }}
                />
            );

            buttonText = t("CONVERT_TO_VIEWER");
        } else if (newRole === "COLLABORATOR") {
            contentText = t("CHANGE_PERMISSIONS_TO_COLLABORATOR", {
                selectedEmail: selectedEmail,
            });
            buttonText = t("CONVERT_TO_COLLABORATOR");
        }

        showMiniDialog({
            title: t("CHANGE_PERMISSION"),
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
            title: t("REMOVE_PARTICIPANT"),
            message: (
                <Trans
                    i18nKey="REMOVE_PARTICIPANT_MESSAGE"
                    values={{
                        selectedEmail: selectedParticipant.email,
                    }}
                />
            ),
            continue: {
                text: t("CONFIRM_REMOVE"),
                color: "critical",
                action: handleRemove,
            },
        });
    };

    if (!selectedParticipant) {
        return <></>;
    }

    return (
        <SidebarDrawer anchor="right" open={open} onClose={handleDrawerClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <Titlebar
                    onClose={onClose}
                    title={t("MANAGE")}
                    onRootClose={onRootClose}
                    caption={selectedParticipant.email}
                />

                <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                    <Stack>
                        <Typography
                            variant="small"
                            sx={{ color: "text.muted", padding: 1 }}
                        >
                            {t("ADDED_AS")}
                        </Typography>

                        <MenuItemGroup>
                            <EnteMenuItem
                                fontWeight="normal"
                                onClick={handleRoleChange("COLLABORATOR")}
                                label={"Collaborator"}
                                startIcon={<ModeEditIcon />}
                                endIcon={
                                    selectedParticipant.role ===
                                        "COLLABORATOR" && <DoneIcon />
                                }
                            />
                            <MenuItemDivider hasIcon />

                            <EnteMenuItem
                                fontWeight="normal"
                                onClick={handleRoleChange("VIEWER")}
                                label={"Viewer"}
                                startIcon={<PhotoIcon />}
                                endIcon={
                                    selectedParticipant.role === "VIEWER" && (
                                        <DoneIcon />
                                    )
                                }
                            />
                        </MenuItemGroup>

                        <Typography
                            variant="small"
                            sx={{ color: "text.muted", padding: 1 }}
                        >
                            {t("COLLABORATOR_RIGHTS")}
                        </Typography>

                        <Stack sx={{ py: "30px" }}>
                            <Typography
                                variant="small"
                                sx={{ color: "text.muted", padding: 1 }}
                            >
                                {t("REMOVE_PARTICIPANT_HEAD")}
                            </Typography>

                            <MenuItemGroup>
                                <EnteMenuItem
                                    color="critical"
                                    fontWeight="normal"
                                    onClick={removeParticipant}
                                    label={"Remove"}
                                    startIcon={<BlockIcon />}
                                />
                            </MenuItemGroup>
                        </Stack>
                    </Stack>
                </Stack>
            </Stack>
        </SidebarDrawer>
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
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);
    const {
        show: showPublicLinkCreated,
        props: publicLinkCreatedVisibilityProps,
    } = useModalVisibility();

    useEffect(() => {
        if (collection.publicURLs?.length) {
            setPublicShareProp(collection.publicURLs[0]);
        }
    }, [collection]);

    useEffect(() => {
        if (publicShareProp?.url) {
            appendCollectionKeyToShareURL(
                publicShareProp.url,
                collection.key,
            ).then((url) => setPublicShareUrl(url));
        } else {
            setPublicShareUrl(null);
        }
    }, [publicShareProp]);

    const copyToClipboardHelper = () => {
        navigator.clipboard.writeText(publicShareUrl);
    };

    return (
        <>
            {publicShareProp ? (
                <ManagePublicShare
                    publicShareProp={publicShareProp}
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    publicShareUrl={publicShareUrl}
                    onRootClose={onRootClose}
                    copyToClipboardHelper={copyToClipboardHelper}
                />
            ) : (
                <EnablePublicShareOptions
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    onLinkCreated={showPublicLinkCreated}
                />
            )}
            <PublicLinkCreated
                {...publicLinkCreatedVisibilityProps}
                onCopyLink={copyToClipboardHelper}
            />
        </>
    );
};

interface ManagePublicShareProps {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    onRootClose: () => void;
    publicShareUrl: string;
    copyToClipboardHelper: () => void;
}

const ManagePublicShare: React.FC<ManagePublicShareProps> = ({
    publicShareProp,
    setPublicShareProp,
    collection,
    onRootClose,
    publicShareUrl,
    copyToClipboardHelper,
}) => {
    const [manageShareView, setManageShareView] = useState(false);
    const closeManageShare = () => setManageShareView(false);
    const openManageShare = () => setManageShareView(true);
    return (
        <>
            <Stack>
                <Typography
                    variant="small"
                    sx={{ color: "text.muted", padding: 1 }}
                >
                    <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                    {t("PUBLIC_LINK_ENABLED")}
                </Typography>
                <MenuItemGroup>
                    {isLinkExpired(publicShareProp.validTill) ? (
                        <EnteMenuItem
                            disabled
                            startIcon={<ErrorOutlineIcon />}
                            color="critical"
                            onClick={openManageShare}
                            label={t("link_expired")}
                        />
                    ) : (
                        <EnteMenuItem
                            startIcon={<ContentCopyIcon />}
                            onClick={copyToClipboardHelper}
                            disabled={isLinkExpired(publicShareProp.validTill)}
                            label={t("copy_link")}
                        />
                    )}

                    <MenuItemDivider hasIcon={true} />
                    <EnteMenuItem
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={openManageShare}
                        label={t("MANAGE_LINK")}
                    />
                </MenuItemGroup>
            </Stack>
            <ManagePublicShareOptions
                open={manageShareView}
                onClose={closeManageShare}
                onRootClose={onRootClose}
                publicShareProp={publicShareProp}
                collection={collection}
                setPublicShareProp={setPublicShareProp}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
};

const isLinkExpired = (validTill: number) => {
    return validTill && validTill < Date.now() * 1000;
};

interface ManagePublicShareOptionsProps {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    publicShareUrl: string;
}

const ManagePublicShareOptions: React.FC<ManagePublicShareOptionsProps> = ({
    publicShareProp,
    collection,
    setPublicShareProp,
    open,
    onClose,
    onRootClose,
    publicShareUrl,
}) => {
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onRootClose();
        } else {
            onClose();
        }
    };
    const galleryContext = useContext(GalleryContext);

    const [sharableLinkError, setSharableLinkError] = useState(null);

    const updatePublicShareURLHelper = async (req: UpdatePublicURL) => {
        try {
            galleryContext.setBlockingLoad(true);
            const response = await updateShareableURL(req);
            setPublicShareProp(response);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const disablePublicSharing = async () => {
        try {
            galleryContext.setBlockingLoad(true);
            await deleteShareableURL(collection);
            setPublicShareProp(null);
            galleryContext.syncWithRemote(false, true);
            onClose();
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
    };
    return (
        <SidebarDrawer anchor="right" open={open} onClose={handleDrawerClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <Titlebar
                    onClose={onClose}
                    title={t("share_album")}
                    onRootClose={onRootClose}
                />
                <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                    <Stack spacing={3}>
                        <ManagePublicCollect
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManageLinkExpiry
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                            onRootClose={onRootClose}
                        />
                        <MenuItemGroup>
                            <ManageDeviceLimit
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                                onRootClose={onRootClose}
                            />
                            <MenuItemDivider />
                            <ManageDownloadAccess
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                            <MenuItemDivider />
                            <ManageLinkPassword
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                        </MenuItemGroup>
                        <MenuItemGroup>
                            <EnteMenuItem
                                startIcon={<ContentCopyIcon />}
                                onClick={copyToClipboardHelper(publicShareUrl)}
                                label={t("copy_link")}
                            />
                        </MenuItemGroup>
                        <MenuItemGroup>
                            <EnteMenuItem
                                color="critical"
                                startIcon={<RemoveCircleOutlineIcon />}
                                onClick={disablePublicSharing}
                                label={t("REMOVE_LINK")}
                            />
                        </MenuItemGroup>
                    </Stack>
                    {sharableLinkError && (
                        <Typography
                            variant="small"
                            sx={(theme) => ({
                                color: theme.colors.danger.A700,
                                mt: 0.5,
                                textAlign: "center",
                            })}
                        >
                            {sharableLinkError}
                        </Typography>
                    )}
                </Stack>
            </Stack>
        </SidebarDrawer>
    );
};

interface ManagePublicCollectProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManagePublicCollect: React.FC<ManagePublicCollectProps> = ({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}) => {
    const handleFileDownloadSetting = () => {
        updatePublicShareURLHelper({
            collectionID: collection.id,
            enableCollect: !publicShareProp.enableCollect,
        });
    };

    return (
        <Stack>
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={handleFileDownloadSetting}
                    variant="toggle"
                    checked={publicShareProp?.enableCollect}
                    label={t("PUBLIC_COLLECT")}
                />
            </MenuItemGroup>
            <MenuSectionTitle title={t("PUBLIC_COLLECT_SUBTEXT")} />
        </Stack>
    );
};

interface ManageLinkExpiryProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

const ManageLinkExpiry: React.FC<ManageLinkExpiryProps> = ({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
    onRootClose,
}) => {
    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            validTill: optionFn,
        });
    };

    const [shareExpiryOptionsModalView, setShareExpiryOptionsModalView] =
        useState(false);

    const shareExpireOption = useMemo(() => shareExpiryOptions(), []);

    const closeShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(false);

    const openShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(true);

    const changeShareExpiryValue = (value: number) => async () => {
        await updateDeviceExpiry(value);
        publicShareProp.validTill = value;
        setShareExpiryOptionsModalView(false);
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onRootClose();
        } else {
            closeShareExpiryOptionsModalView();
        }
    };

    return (
        <>
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={openShareExpiryOptionsModalView}
                    endIcon={<ChevronRightIcon />}
                    variant="captioned"
                    label={t("LINK_EXPIRY")}
                    color={
                        isLinkExpired(publicShareProp?.validTill)
                            ? "critical"
                            : "primary"
                    }
                    subText={
                        isLinkExpired(publicShareProp?.validTill)
                            ? t("link_expired")
                            : publicShareProp?.validTill
                              ? formatDateTime(
                                    publicShareProp?.validTill / 1000,
                                )
                              : t("never")
                    }
                />
            </MenuItemGroup>
            <SidebarDrawer
                anchor="right"
                open={shareExpiryOptionsModalView}
                onClose={handleDrawerClose}
            >
                <Stack sx={{ gap: "4px", py: "12px" }}>
                    <Titlebar
                        onClose={closeShareExpiryOptionsModalView}
                        title={t("LINK_EXPIRY")}
                        onRootClose={onRootClose}
                    />
                    <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                        <MenuItemGroup>
                            {shareExpireOption.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item.value()}
                                        onClick={changeShareExpiryValue(
                                            item.value(),
                                        )}
                                        label={item.label}
                                    />
                                    {index !== shareExpireOption.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                </Stack>
            </SidebarDrawer>
        </>
    );
};

export const shareExpiryOptions = () => [
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

interface ManageDeviceLimitProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

const ManageDeviceLimit: React.FC<ManageDeviceLimitProps> = ({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    onRootClose,
}) => {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };
    const [isChangeDeviceLimitVisible, setIsChangeDeviceLimitVisible] =
        useState(false);
    const deviceLimitOptions = useMemo(() => getDeviceLimitOptions(), []);

    const closeDeviceLimitChangeModal = () =>
        setIsChangeDeviceLimitVisible(false);
    const openDeviceLimitChangeModalView = () =>
        setIsChangeDeviceLimitVisible(true);

    const changeDeviceLimitValue = (value: number) => async () => {
        await updateDeviceLimit(value);
        setIsChangeDeviceLimitVisible(false);
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onRootClose();
        } else {
            closeDeviceLimitChangeModal();
        }
    };

    return (
        <>
            <EnteMenuItem
                label={t("LINK_DEVICE_LIMIT")}
                variant="captioned"
                subText={
                    publicShareProp.deviceLimit === 0
                        ? t("NO_DEVICE_LIMIT")
                        : publicShareProp.deviceLimit.toString()
                }
                onClick={openDeviceLimitChangeModalView}
                endIcon={<ChevronRightIcon />}
            />
            <SidebarDrawer
                anchor="right"
                open={isChangeDeviceLimitVisible}
                onClose={handleDrawerClose}
            >
                <Stack sx={{ gap: "4px", py: "12px" }}>
                    <Titlebar
                        onClose={closeDeviceLimitChangeModal}
                        title={t("LINK_DEVICE_LIMIT")}
                        onRootClose={onRootClose}
                    />
                    <Stack sx={{ gap: "32px", py: "20px", px: "8px" }}>
                        <MenuItemGroup>
                            {deviceLimitOptions.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item.label}
                                        onClick={changeDeviceLimitValue(
                                            item.value,
                                        )}
                                        label={item.label}
                                    />
                                    {index !==
                                        deviceLimitOptions.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                </Stack>
            </SidebarDrawer>
        </>
    );
};

interface ManageDownloadAccessProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManageDownloadAccess: React.FC<ManageDownloadAccessProps> = ({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}) => {
    const { showMiniDialog } = useAppContext();

    const handleFileDownloadSetting = () => {
        if (publicShareProp.enableDownload) {
            disableFileDownload();
        } else {
            updatePublicShareURLHelper({
                collectionID: collection.id,
                enableDownload: true,
            });
        }
    };

    const disableFileDownload = () => {
        showMiniDialog({
            title: t("disable_file_download"),
            message: <Trans i18nKey={"disable_file_download_message"} />,
            continue: {
                text: t("disable"),
                color: "critical",
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        enableDownload: false,
                    }),
            },
        });
    };
    return (
        <EnteMenuItem
            checked={publicShareProp?.enableDownload ?? true}
            onClick={handleFileDownloadSetting}
            variant="toggle"
            label={t("FILE_DOWNLOAD")}
        />
    );
};

interface ManageLinkPasswordProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManageLinkPassword: React.FC<ManageLinkPasswordProps> = ({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
}) => {
    const { showMiniDialog } = useAppContext();
    const [changePasswordView, setChangePasswordView] = useState(false);

    const closeConfigurePassword = () => setChangePasswordView(false);

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await confirmDisablePublicUrlPassword();
        } else {
            setChangePasswordView(true);
        }
    };

    const confirmDisablePublicUrlPassword = async () => {
        showMiniDialog({
            title: t("disable_password"),
            message: t("disable_password_message"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        disablePassword: true,
                    }),
            },
        });
    };

    return (
        <>
            <EnteMenuItem
                label={t("password_lock")}
                onClick={handlePasswordChangeSetting}
                checked={!!publicShareProp?.passwordEnabled}
                variant="toggle"
            />
            <PublicLinkSetPassword
                open={changePasswordView}
                onClose={closeConfigurePassword}
                collection={collection}
                publicShareProp={publicShareProp}
                updatePublicShareURLHelper={updatePublicShareURLHelper}
                setChangePasswordView={setChangePasswordView}
            />
        </>
    );
};

function PublicLinkSetPassword({
    open,
    onClose,
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const savePassword: SingleInputFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        if (passphrase && passphrase.trim().length >= 1) {
            await enablePublicUrlPassword(passphrase);
            setChangePasswordView(false);
            publicShareProp.passwordEnabled = true;
        } else {
            setFieldError("can not be empty");
        }
    };

    const enablePublicUrlPassword = async (password: string) => {
        const cryptoWorker = await sharedCryptoWorker();
        const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
        const kek = await cryptoWorker.deriveInteractiveKey(password, kekSalt);

        return updatePublicShareURLHelper({
            collectionID: collection.id,
            passHash: kek.key,
            nonce: kekSalt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };
    return (
        <Dialog
            open={open}
            onClose={onClose}
            disablePortal
            slotProps={{ backdrop: { sx: { position: "absolute" } } }}
            sx={{ position: "absolute" }}
            PaperProps={{ sx: { p: 1 } }}
            maxWidth={"sm"}
            fullWidth
        >
            <Stack sx={{ gap: 3, p: 1.5 }}>
                <Typography
                    variant="h3"
                    sx={{ fontWeight: "bold", px: 1, py: 0.5 }}
                >
                    {t("password_lock")}
                </Typography>
                <SingleInputForm
                    callback={savePassword}
                    placeholder={t("password")}
                    buttonText={t("lock")}
                    fieldType="password"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </Stack>
        </Dialog>
    );
}
