import type { CollectionsSortBy } from "@/new/photos/types/collection";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import TickIcon from "@mui/icons-material/Done";
import SortIcon from "@mui/icons-material/Sort";
import SvgIcon from "@mui/material/SvgIcon";
import { t } from "i18next";

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
export const CollectionsSortOptions: React.FC<CollectionsSortOptionsProps> = (
    props,
) => {
    const SortByOption = SortByOptionCreator(props);

    return (
        <OverflowMenu
            ariaControls="collection-sort"
            triggerButtonIcon={<SortIcon />}
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        props.nestedInDialog &&
                        theme.colors.background.elevated2,
                },
            }}
            triggerButtonProps={{
                sx: {
                    background: (theme) =>
                        !props.disableTriggerButtonBackground &&
                        theme.colors.fill.faint,
                },
            }}
        >
            <SortByOption sortBy="name">{t("sort_by_name")}</SortByOption>
            <SortByOption sortBy="creation-time-asc">
                {t("sort_by_creation_time_ascending")}
            </SortByOption>
            <SortByOption sortBy="updation-time-desc">
                {t("sort_by_updation_time_descending")}
            </SortByOption>
        </OverflowMenu>
    );
};

const SortByOptionCreator =
    ({ onChangeSortBy, activeSortBy }: CollectionsSortOptionsProps) =>
    (props: { sortBy: CollectionsSortBy; children: any }) => {
        const handleClick = () => {
            onChangeSortBy(props.sortBy);
        };

        return (
            <OverflowMenuOption
                onClick={handleClick}
                endIcon={
                    activeSortBy === props.sortBy ? <TickIcon /> : <SvgIcon />
                }
            >
                {props.children}
            </OverflowMenuOption>
        );
    };
