import {
    LegacyDrawerContent,
    type LegacySuggestedUser,
} from "ente-contacts-web/legacy";
import React from "react";
import {
    LockerTitledNestedSidebarDrawer,
    type LockerNestedSidebarDrawerVisibilityProps,
} from "./LockerSidebarShell";

export const LockerLegacyDrawer: React.FC<
    LockerNestedSidebarDrawerVisibilityProps & {
        suggestedUsers: LegacySuggestedUser[];
    }
> = ({ open, onClose, onRootClose, suggestedUsers }) => (
    <LockerTitledNestedSidebarDrawer
        {...{ open, onClose, onRootClose }}
        title="Legacy"
        caption="Legacy allows trusted contacts to access your account in your absence."
    >
        <LegacyDrawerContent open={open} suggestedUsers={suggestedUsers} />
    </LockerTitledNestedSidebarDrawer>
);
