import ChevronRight from "@mui/icons-material/ChevronRight";
import { DialogProps, Stack } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import MenuItemDivider from "components/Menu/MenuItemDivider";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { useMemo, useState } from "react";
import { Collection, PublicURL, UpdatePublicURL } from "types/collection";
import { getDeviceLimitOptions } from "utils/collection";

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

export function ManageDeviceLimit({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    onRootClose,
}: Iprops) {
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
        if (reason === "backdropClick") {
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
                endIcon={<ChevronRight />}
            />

            <EnteDrawer
                anchor="right"
                open={isChangeDeviceLimitVisible}
                onClose={handleDrawerClose}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={closeDeviceLimitChangeModal}
                        title={t("LINK_DEVICE_LIMIT")}
                        onRootClose={onRootClose}
                    />
                    <Stack py={"20px"} px={"8px"} spacing={"32px"}>
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
            </EnteDrawer>
        </>
    );
}
