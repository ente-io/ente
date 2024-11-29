import type { CollectionsSortBy } from "@/new/photos/services/collection/ui";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@ente/shared/components/OverflowMenu";
import TickIcon from "@mui/icons-material/Done";
import SortIcon from "@mui/icons-material/Sort";
import SvgIcon from "@mui/material/SvgIcon";
import { t } from "i18next";
import React from "react";

interface CollectionsSortOptionsProps {
    /**
     * The sorting scheme currently active.
     */
    activeSortBy: CollectionsSortBy;
    /**
     * Change the scheme that should be used.
     */
    onChangeSortBy: (by: CollectionsSortBy) => void;
    /**
     * Set this to true if we're being shown inside a dialog, to further
     * increase the elevation of the menu.
     */
    nestedInDialog?: boolean;
    /**
     * Set this to true to disable the background in the button that triggers
     * the menu.
     */
    disableTriggerButtonBackground?: boolean;
}

/**
 * A button that shows an overflow menu allowing the user to choose from amongst
 * the {@link CollectionsSortBy} values that should be used for sorting the
 * lists of collections.
 */
export const CollectionsSortOptions: React.FC<CollectionsSortOptionsProps> = ({
    nestedInDialog,
    disableTriggerButtonBackground,
    ...optProps
}) => (
    <OverflowMenu
        ariaID="collection-sort"
        triggerButtonIcon={<SortIcon />}
        menuPaperProps={{
            sx: {
                backgroundColor: (theme) =>
                    nestedInDialog
                        ? theme.colors.background.elevated2
                        : undefined,
            },
        }}
        triggerButtonProps={{
            sx: {
                backgroundColor: (theme) =>
                    disableTriggerButtonBackground
                        ? undefined
                        : theme.colors.fill.faint,
            },
        }}
    >
        <SortByOption {...optProps} sortBy="name">
            {t("name")}
        </SortByOption>
        <SortByOption {...optProps} sortBy="creation-time-asc">
            {t("oldest")}
        </SortByOption>
        <SortByOption {...optProps} sortBy="updation-time-desc">
            {t("last_updated")}
        </SortByOption>
    </OverflowMenu>
);

type SortByOptionProps = Pick<
    CollectionsSortOptionsProps,
    "activeSortBy" | "onChangeSortBy"
> & {
    sortBy: CollectionsSortBy;
};

const SortByOption: React.FC<React.PropsWithChildren<SortByOptionProps>> = ({
    sortBy,
    activeSortBy,
    onChangeSortBy,
    children,
}) => {
    const handleClick = () => onChangeSortBy(sortBy);

    return (
        <OverflowMenuOption
            onClick={handleClick}
            endIcon={activeSortBy == sortBy ? <TickIcon /> : <SvgIcon />}
        >
            {children}
        </OverflowMenuOption>
    );
};
