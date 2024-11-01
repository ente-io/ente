import { MenuItemDivider, MenuItemGroup } from "@/base/components/Menu";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import type {
    Collection,
    PublicURL,
    UpdatePublicURL,
} from "@/media/collection";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { formatDateTime } from "@ente/shared/time/format";
import ChevronRight from "@mui/icons-material/ChevronRight";
import { DialogProps, Stack } from "@mui/material";
import { t } from "i18next";
import { useMemo, useState } from "react";
import { shareExpiryOptions } from "utils/collection";
import { isLinkExpired } from "../managePublicShare";

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

export function ManageLinkExpiry({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
    onRootClose,
}: Iprops) {
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
        if (reason === "backdropClick") {
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
                    endIcon={<ChevronRight />}
                    variant="captioned"
                    label={t("LINK_EXPIRY")}
                    color={
                        isLinkExpired(publicShareProp?.validTill)
                            ? "critical"
                            : "primary"
                    }
                    subText={
                        isLinkExpired(publicShareProp?.validTill)
                            ? t("LINK_EXPIRED")
                            : publicShareProp?.validTill
                              ? formatDateTime(
                                    publicShareProp?.validTill / 1000,
                                )
                              : t("NEVER")
                    }
                />
            </MenuItemGroup>
            <SidebarDrawer
                anchor="right"
                open={shareExpiryOptionsModalView}
                onClose={handleDrawerClose}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={closeShareExpiryOptionsModalView}
                        title={t("LINK_EXPIRY")}
                        onRootClose={onRootClose}
                    />
                    <Stack py={"20px"} px={"8px"} spacing={"32px"}>
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
}
