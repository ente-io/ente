import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import type { Collection } from "@/media/collection";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import { DialogProps, Stack } from "@mui/material";
import { t } from "i18next";
import EmailShare from "./emailShare";
import PublicShare from "./publicShare";
import SharingDetails from "./sharingDetails";

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    collectionSummary: CollectionSummary;
}

function CollectionShare({ collectionSummary, ...props }: Props) {
    const handleRootClose = () => {
        props.onClose();
    };
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
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
            <Stack spacing={"4px"} py={"12px"}>
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
                <Stack py={"20px"} px={"8px"} gap={"24px"}>
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
}
export default CollectionShare;
