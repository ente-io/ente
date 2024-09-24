import type { Person } from "@/new/photos/services/ml/cgroups";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import EditIcon from "@mui/icons-material/Edit";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { t } from "i18next";
import React from "react";
import { SpaceBetweenFlex } from "../mui-custom";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

interface PeopleListHeaderProps {
    person: Person;
}

export const PersonListHeader: React.FC<PeopleListHeaderProps> = ({
    person,
}) => {
    const hasOptions = process.env.NEXT_PUBLIC_ENTE_WIP_CL;
    return (
        <GalleryItemsHeaderAdapter>
            <SpaceBetweenFlex>
                <GalleryItemsSummary
                    name={person.name ?? "Unnamed person"}
                    fileCount={person.fileIDs.length}
                />
                {hasOptions && (
                    <OverflowMenu
                        ariaControls={"person-options"}
                        triggerButtonIcon={<MoreHoriz />}
                    >
                        <OverflowMenuOption
                            startIcon={<EditIcon />}
                            onClick={() => console.log("test")}
                        >
                            {t("download_album")}
                        </OverflowMenuOption>
                    </OverflowMenu>
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};
