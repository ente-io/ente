import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import TickIcon from "@mui/icons-material/Done";
import SortIcon from "@mui/icons-material/Sort";
import SvgIcon from "@mui/material/SvgIcon";
import { t } from "i18next";
import { COLLECTION_LIST_SORT_BY } from "utils/collection";

interface CollectionListSortOptionsProps {
    setSortBy: (sortBy: COLLECTION_LIST_SORT_BY) => void;
    activeSortBy: COLLECTION_LIST_SORT_BY;
    nestedInDialog?: boolean;
    disableBG?: boolean;
}

const SortByOptionCreator =
    ({ setSortBy, activeSortBy }: CollectionListSortOptionsProps) =>
    (props: { sortBy: COLLECTION_LIST_SORT_BY; children: any }) => {
        const handleClick = () => {
            setSortBy(props.sortBy);
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

export const CollectionListSortOptions: React.FC<
    CollectionListSortOptionsProps
> = (props) => {
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
                        !props.disableBG && theme.colors.fill.faint,
                },
            }}
        >
            <SortByOption sortBy={COLLECTION_LIST_SORT_BY.NAME}>
                {t("sort_by_name")}
            </SortByOption>
            <SortByOption
                sortBy={COLLECTION_LIST_SORT_BY.CREATION_TIME_ASCENDING}
            >
                {t("sort_by_creation_time_ascending")}
            </SortByOption>
            <SortByOption
                sortBy={COLLECTION_LIST_SORT_BY.UPDATION_TIME_DESCENDING}
            >
                {t("sort_by_updation_time_descending")}
            </SortByOption>
        </OverflowMenu>
    );
};
