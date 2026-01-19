import { ArrowDown02Icon, ArrowUp02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import SortIcon from "@mui/icons-material/Sort";
import {
    IconButton,
    MenuItem,
    Stack,
    Typography,
    type IconButtonProps,
    type PaperProps,
} from "@mui/material";
import Menu, { type MenuProps } from "@mui/material/Menu";
import type { CollectionsSortBy } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import React, { useState } from "react";

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
     * Set this to true to disable the background for the icon button that
     * triggers the menu.
     */
    transparentTriggerButtonBackground?: boolean;
}

/** The three sort categories. */
type SortCategory = "name" | "creation-time" | "updation-time";

/** Extract the category from a CollectionsSortBy value. */
const getSortCategory = (sortBy: CollectionsSortBy): SortCategory => {
    if (sortBy.startsWith("name")) return "name";
    if (sortBy.startsWith("creation-time")) return "creation-time";
    return "updation-time";
};

/** Check if the sort is ascending. */
const isAscending = (sortBy: CollectionsSortBy): boolean =>
    sortBy.endsWith("-asc");

/** Get the CollectionsSortBy value for a category and direction. */
const getSortBy = (
    category: SortCategory,
    ascending: boolean,
): CollectionsSortBy => `${category}-${ascending ? "asc" : "desc"}`;

/**
 * A button that shows an overflow menu allowing the user to choose from amongst
 * the {@link CollectionsSortBy} values that should be used for sorting the
 * lists of collections.
 */
export const CollectionsSortOptions: React.FC<CollectionsSortOptionsProps> = ({
    activeSortBy,
    onChangeSortBy,
    nestedInDialog,
    transparentTriggerButtonBackground,
}) => {
    const [anchorEl, setAnchorEl] = useState<MenuProps["anchorEl"]>();
    const ariaID = "collection-sort";

    const activeCategory = getSortCategory(activeSortBy);
    const activeAscending = isAscending(activeSortBy);

    const handleCategoryClick = (category: SortCategory) => {
        if (category === activeCategory) {
            // Toggle direction if same category
            onChangeSortBy(getSortBy(category, !activeAscending));
        } else {
            // Select new category with default direction
            const defaultAscending = category === "name"; // Name defaults to A-Z (asc), dates to newest (desc)
            onChangeSortBy(getSortBy(category, defaultAscending));
        }
        setAnchorEl(undefined);
    };

    const triggerButtonSxProps: IconButtonProps["sx"] = [
        transparentTriggerButtonBackground
            ? {}
            : { backgroundColor: "fill.faint" },
    ];

    const menuPaperSxProps: PaperProps["sx"] = [
        { marginBlock: 1, borderRadius: 2, overflow: "hidden" },
        nestedInDialog ? { backgroundColor: "background.paper2" } : {},
    ];

    return (
        <>
            <IconButton
                onClick={(event) => setAnchorEl(event.currentTarget)}
                aria-controls={anchorEl ? ariaID : undefined}
                aria-haspopup="true"
                aria-expanded={anchorEl ? "true" : undefined}
                sx={triggerButtonSxProps}
            >
                <SortIcon />
            </IconButton>
            <Menu
                id={ariaID}
                {...(anchorEl && { anchorEl })}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                slotProps={{
                    paper: { sx: menuPaperSxProps },
                    list: { disablePadding: true, "aria-labelledby": ariaID },
                }}
                anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
                transformOrigin={{ vertical: "top", horizontal: "right" }}
            >
                <SortCategoryOption
                    category="name"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("name")}
                    ascLabel={t("sort_asc_indicator")}
                    descLabel={t("sort_desc_indicator")}
                    showBorder
                />
                <SortCategoryOption
                    category="creation-time"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("created")}
                    ascLabel={t("sort_oldest")}
                    descLabel={t("sort_newest")}
                    showBorder
                />
                <SortCategoryOption
                    category="updation-time"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("updated")}
                    ascLabel={t("sort_oldest")}
                    descLabel={t("sort_newest")}
                />
            </Menu>
        </>
    );
};

interface SortCategoryOptionProps {
    category: SortCategory;
    activeCategory: SortCategory;
    activeAscending: boolean;
    onClick: (category: SortCategory) => void;
    label: string;
    ascLabel: string;
    descLabel: string;
    showBorder?: boolean;
}

const SortCategoryOption: React.FC<SortCategoryOptionProps> = ({
    category,
    activeCategory,
    activeAscending,
    onClick,
    label,
    ascLabel,
    descLabel,
    showBorder,
}) => {
    const isSelected = category === activeCategory;
    const directionLabel = activeAscending ? ascLabel : descLabel;
    const arrowIcon = activeAscending ? ArrowUp02Icon : ArrowDown02Icon;

    return (
        <MenuItem
            disableGutters
            onClick={() => onClick(category)}
            sx={{
                minWidth: 220,
                minHeight: 56,
                py: 2,
                px: 2.5,
                display: "flex",
                alignItems: "center",
                borderBottom: showBorder ? "1px solid" : "none",
                borderColor: "divider",
            }}
        >
            <Stack direction="row" sx={{ alignItems: "center" }}>
                <Typography
                    sx={{
                        color: isSelected ? "text.primary" : "text.secondary",
                    }}
                >
                    {label}
                </Typography>
                {isSelected && (
                    <Stack
                        direction="row"
                        sx={{
                            alignItems: "center",
                            ml: 1,
                            gap: 0.75,
                            color: "text.muted",
                        }}
                    >
                        <Typography>•</Typography>
                        <Typography sx={{ fontSize: "0.875rem" }}>
                            {directionLabel}
                        </Typography>
                        <HugeiconsIcon
                            icon={arrowIcon}
                            size={18}
                            color="currentColor"
                        />
                    </Stack>
                )}
            </Stack>
        </MenuItem>
    );
};
