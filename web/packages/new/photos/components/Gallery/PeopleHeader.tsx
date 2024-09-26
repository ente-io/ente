/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import { pt } from "@/base/i18n";
import { addPerson, renamePerson } from "@/new/photos/services/ml/";
import { type Person } from "@/new/photos/services/ml/people";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { IconButton, Stack, Tooltip } from "@mui/material";
import { t } from "i18next";
import React, { useState } from "react";
import type { FaceCluster } from "../../services/ml/cluster";
import type { CGroup } from "../../services/user-entity";
import type { NewAppContextPhotos } from "../../types/context";
import { SpaceBetweenFlex } from "../mui-custom";
import { NameInputDialog } from "../NameInputDialog";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

interface PeopleHeaderProps {
    person: Person;
    appContext: NewAppContextPhotos;
}

export const PeopleHeader: React.FC<PeopleHeaderProps> = ({
    person,
    appContext,
}) => {
    return (
        <GalleryItemsHeaderAdapter>
            <SpaceBetweenFlex>
                <GalleryItemsSummary
                    name={
                        person.name ?? pt("Unnamed person") /* TODO-Cluster */
                    }
                    nameProps={person.name ? {} : { color: "text.muted" }}
                    fileCount={person.fileIDs.length}
                />
                {person.type == "cgroup" ? (
                    <CGroupPersonOptions
                        cgroup={person.cgroup}
                        appContext={appContext}
                    />
                ) : (
                    <ClusterPersonOptions
                        cluster={person.cluster}
                        appContext={appContext}
                    />
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

interface CGroupPersonOptionsProps {
    cgroup: CGroup;
    appContext: NewAppContextPhotos;
}

const CGroupPersonOptions: React.FC<CGroupPersonOptionsProps> = ({
    cgroup,
    appContext,
}) => {
    const { startLoading, finishLoading } = appContext;

    const [openAddNameInput, setOpenAddNameInput] = useState(false);

    const handleRenamePerson = () => setOpenAddNameInput(true);

    const renamePersonUsingName = async (name: string) => {
        startLoading();
        try {
            await renamePerson(name, cgroup);
        } finally {
            finishLoading();
        }
    };

    return (
        <>
            <OverflowMenu
                ariaControls={"person-options"}
                triggerButtonIcon={<MoreHoriz />}
            >
                <OverflowMenuOption
                    startIcon={<EditIcon />}
                    centerAlign
                    onClick={handleRenamePerson}
                >
                    {t("rename")}
                </OverflowMenuOption>
            </OverflowMenu>

            <NameInputDialog
                open={openAddNameInput}
                onClose={() => setOpenAddNameInput(false)}
                title={pt("Rename person")}
                placeholder={t("ENTER_NAME") /* TODO-Cluster */}
                initialValue={cgroup.data.name ?? ""}
                submitButtonTitle={t("rename")}
                onSubmit={renamePersonUsingName}
            />
        </>
    );
};

interface ClusterPersonOptionsProps {
    cluster: FaceCluster;
    appContext: NewAppContextPhotos;
}

const ClusterPersonOptions: React.FC<ClusterPersonOptionsProps> = ({
    cluster,
    appContext,
}) => {
    const { startLoading, finishLoading } = appContext;

    const [openNameInput, setOpenNameInput] = useState(false);

    const handleAddPerson = () => setOpenNameInput(true);

    const addPersonWithName = async (name: string) => {
        startLoading();
        try {
            await addPerson(name, cluster);
        } finally {
            finishLoading();
        }
    };

    return (
        <>
            <Stack direction="row" sx={{ alignItems: "center", gap: 2 }}>
                <Tooltip title={pt("Add a name")}>
                    <IconButton onClick={handleAddPerson}>
                        <AddIcon />
                    </IconButton>
                </Tooltip>

                <OverflowMenu
                    ariaControls={"person-options"}
                    triggerButtonIcon={<MoreHoriz />}
                >
                    <OverflowMenuOption
                        startIcon={<AddIcon />}
                        centerAlign
                        onClick={handleAddPerson}
                    >
                        {pt("Add a name")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </Stack>

            <NameInputDialog
                open={openNameInput}
                onClose={() => setOpenNameInput(false)}
                title={pt("Add person")}
                placeholder={t("ENTER_NAME") /* TODO-Cluster */}
                initialValue={""}
                submitButtonTitle={t("ADD")}
                onSubmit={addPersonWithName}
            />
        </>
    );
};
