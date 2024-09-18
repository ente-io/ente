import { masterKeyFromSession } from "@/base/session-store";
import { fileIDFromFaceID, wipClusterEnable } from ".";
import type { EnteFile } from "../../types/file";
import { getLocalFiles } from "../files";
import { pullCGroups } from "../user-entity";
import type { FaceCluster } from "./cluster";
import { getClusterGroups, getFaceIndexes } from "./db";

/**
 * A cgroup ("cluster group") is a group of clusters (possibly containing just a
 * single cluster) that the user has interacted with.
 *
 * Interactions include hiding, merging and giving a name and/or a cover photo.
 *
 * The most frequent interaction is naming a {@link FaceCluster}, which promotes
 * it to a become a {@link CGroup}. The promotion comes with the ability to be
 * synced with remote (as a "cgroup" user entity).
 *
 * There after, the user may attach more clusters to the same {@link CGroup}.
 *
 * > A named cluster group can be thought of as a "person", though this is not
 * > necessarily an accurate characterization. e.g. there can be a named cluster
 * > group that contains face clusters of pets.
 *
 * The other form of interaction is hiding. The user may hide a single (unnamed)
 * cluster, or they may hide an named {@link CGroup}. In both cases, we promote
 * the cluster to a CGroup if needed so that their request to hide gets synced.
 *
 * The user can see both the cgroups and clusters in the UI, but only the
 * cgroups are synced with remote.
 */
export interface CGroup {
    /**
     * A nanoid for this cluster group.
     *
     * This is the ID of the "cgroup" user entity (the envelope), and it is not
     * contained as part of the group entity payload itself.
     */
    id: string;
    /**
     * A name assigned by the user to this cluster group.
     *
     * The client should handle both empty strings and undefined as indicating a
     * cgroup without a name. When the client needs to set this to an "empty"
     * value, which happens when hiding an unnamed cluster, it should it to an
     * empty string. That is, expect `"" | undefined`, but set `""`.
     */
    name: string | undefined;
    /**
     * An unordered set ofe clusters that have been assigned to this group.
     *
     * For ease of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    assigned: FaceCluster[];
    /**
     * True if this cluster group should be hidden.
     *
     * The user can hide both named cluster groups and single unnamed clusters.
     * If the user hides a single cluster that was offered as a suggestion to
     * them on a client, the client will create a new unnamed cgroup containing
     * it, and set its hidden flag to sync it with remote (so that other clients
     * can also stop showing this cluster).
     */
    isHidden: boolean;
    /**
     * The ID of the face that should be used as the cover photo for this
     * cluster group. Optional.
     *
     * This is similar to the [@link displayFaceID}, the difference being:
     *
     * -   {@link avatarFaceID} is the face selected by the user.
     *
     * -   {@link displayFaceID} is the automatic placeholder, and only comes
     *     into effect if the user has not explicitly selected a face.
     */
    avatarFaceID: string | undefined;
}

/**
 * A massaged version of {@link CGroup} suitable for being shown in the UI.
 *
 * The cgroups synced with remote do not directly correspond to "people".
 * CGroups represent both positive and negative feedback, where the negations
 * are specifically feedback meant so that we do not show the corresponding
 * cluster in the UI.
 *
 * So while each person has an underlying cgroups, not all cgroups have a
 * corresponding person.
 *
 * Beyond this semantic difference, there is also data massaging: a
 * {@link Person} has data converted into a format that the UI can directly and
 * efficiently use, as compared to a {@link CGroup}, which is tailored for
 * transmission and storage.
 */
export interface Person {
    /**
     * Nanoid of the underlying {@link CGroup}.
     */
    id: string;
    /**
     * The name of the person.
     */
    name: string;
    /**
     * IDs of the (unique) files in which this face occurs.
     */
    fileIDs: number[];
    /**
     * The face that should be used as the "cover" face to represent this
     * {@link Person} in the UI.
     */
    displayFaceID: string;
    /**
     * The {@link EnteFile} which contains the display face.
     */
    displayFaceFile: EnteFile;
}

// TODO-Cluster remove me
/**
 * A {@link CGroup} annotated with various in-memory state to make it easier for
 * the upper layers of our code to directly use it.
 */
export type AnnotatedCGroup = CGroup & {
    /**
     * Locally determined ID of the "best" face that should be used as the
     * display face, to represent this cluster group in the UI.
     *
     * This property is not synced with remote. For more details, see
     * {@link avatarFaceID}.
     */
    displayFaceID: string | undefined;
};

/**
 * Fetch existing cgroups for the user from remote and save them to DB.
 */
export const syncCGroups = async () => {
    if (!process.env.NEXT_PUBLIC_ENTE_WIP_CL) return;
    if (!(await wipClusterEnable())) return;

    const masterKey = await masterKeyFromSession();
    await pullCGroups(masterKey);
};

/**
 * Construct in-memory "people" from the cgroups present locally.
 *
 * This function is meant to run after files, cgroups and faces have been synced
 * with remote. It then uses all the information in the local DBs to construct
 * an in-memory list of {@link Person}s on which the UI will operate.
 *
 * @return A list of {@link Person}s, sorted by the number of files that they
 * reference.
 */
export const updatedPeople = async () => {
    if (!process.env.NEXT_PUBLIC_ENTE_WIP_CL) return [];
    if (!(await wipClusterEnable())) return [];

    // Ignore faces belonging to deleted (incl Trash) and hidden files.
    //
    // More generally, we should not make strict assumptions about the clusters
    // we get from remote. In particular, the same face ID can be in different
    // clusters. In such cases we should assign it arbitrarily assign it to the
    // last cluster we find it in. Such leeway is intentionally provided to
    // allow clients some slack in how they implement the sync without needing
    // to make an blocking API request for every user interaction.

    const files = await getLocalFiles("normal");
    const fileByID = new Map(files.map((f) => [f.id, f]));

    const faceIndexes = await getFaceIndexes();
    const personFaceByID = new Map<
        string,
        { faceID: string; file: EnteFile; score: number }
    >();
    for (const { faces } of faceIndexes) {
        for (const { faceID, score } of faces) {
            const fileID = fileIDFromFaceID(faceID);
            if (!fileID) continue;
            const file = fileByID.get(fileID);
            if (!file) continue;
            personFaceByID.set(faceID, { faceID, file, score });
        }
    }

    // Convert cgroups to people.
    const cgroups = await getClusterGroups();
    return cgroups
        .map((cgroup) => {
            // Hidden cgroups are clusters specifically marked so as to not be shown
            // in the UI.
            if (cgroup.isHidden) return undefined;

            // Unnamed groups are also not shown.
            const name = cgroup.name;
            if (!name) return undefined;

            // Person faces from all the clusters assigned to this cgroup, sorted by
            // their score.
            const faces = cgroup.assigned
                .map(({ faces }) =>
                    faces
                        .map((id) => personFaceByID.get(id))
                        .filter((f) => !!f),
                )
                .flat()
                .sort((a, b) => b.score - a.score);

            // Ignore this cgroup if we don't have eligible faces left in it.
            const highestScoringFace = faces[0];
            if (!highestScoringFace) return undefined;

            // IDs of the files containing this face.
            const fileIDs = [...new Set(faces.map((f) => f.file.id))];

            // Avatar face ID, or the highest scoring face.
            const avatarFaceID = cgroup.avatarFaceID;
            let avatarFile: EnteFile | undefined;
            if (avatarFaceID) {
                const avatarFileID = fileIDFromFaceID(avatarFaceID);
                if (avatarFileID) {
                    avatarFile = fileByID.get(avatarFileID);
                }
            }

            let displayFaceID: string;
            let displayFaceFile: EnteFile;
            if (avatarFaceID && avatarFile) {
                displayFaceID = avatarFaceID;
                displayFaceFile = avatarFile;
            } else {
                displayFaceID = highestScoringFace.faceID;
                displayFaceFile = highestScoringFace.file;
            }

            const id = cgroup.id;

            return { id, name, fileIDs, displayFaceID, displayFaceFile };
        })
        .filter((c) => !!c)
        .sort((a, b) => b.fileIDs.length - a.fileIDs.length);
};
