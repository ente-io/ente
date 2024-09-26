import { wipClusterEnable } from ".";
import type { EnteFile } from "../../types/file";
import { getLocalFiles } from "../files";
import { savedCGroupUserEntities } from "../user-entity";
import type { FaceCluster } from "./cluster";
import { getFaceIndexes, savedFaceClusters } from "./db";
import { fileIDFromFaceID } from "./face";

/**
 * A cgroup ("cluster group") is a group of clusters (possibly containing just a
 * single cluster) that the user has interacted with.
 *
 * Interactions include hiding, merging and giving a name and/or a cover photo.
 *
 * The most frequent interaction is naming a {@link FaceCluster}, which promotes
 * it to a become a {@link CGroupUserEntity}. The promotion comes with the
 * ability to be synced with remote (as a "cgroup" user entity).
 *
 * There after, the user may attach more clusters to the same cgroup.
 *
 * > A named cluster group can be thought of as a "person", though this is not
 * > necessarily an accurate characterization. e.g. there can be a named cluster
 * > group that contains face clusters of pets.
 *
 * The other form of interaction is hiding. The user may hide a single (unnamed)
 * cluster, or they may hide an named cgroup. In both cases, we promote the
 * cluster to a cgroup if needed so that their request to hide gets synced.
 *
 * The user can see both the cgroups and clusters in the UI, but only the
 * cgroups are synced with remote.
 */
export interface CGroupUserEntityData {
    /**
     * A name assigned by the user to this cluster group.
     *
     * The client should handle both empty strings and undefined as indicating a
     * cgroup without a name. When the client needs to set this to an <empty>
     * value, which happens when hiding an unnamed cluster, it should it to an
     * empty string. That is, expect `"" | undefined`, but set `""`.
     *
     * [Note: Mark optional for Zod/exactOptionalPropertyTypes]
     *
     * The type is marked as an optional (?) because currently Zod does not
     * differentiate between optionals and undefined-valued properties as
     * required by exactOptionalPropertyTypes.
     */
    name?: string | undefined;
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
     *
     * Also, see: [Note: Mark optional for Zod/exactOptionalPropertyTypes]
     */
    avatarFaceID?: string | undefined;
}

/**
 * A massaged version of {@link CGroupUserEntityData} or a {@link FaceCluster}
 * suitable for being shown in the UI.
 *
 * We transform both both remote cluster groups and local-only face clusters
 * into the same "person" object that can be shown in the UI.
 *
 * The cgroups synced with remote do not directly correspond to "people".
 * CGroups represent both positive and negative feedback (i.e, the user does not
 * wish a particular cluster group to be shown in the UI).
 *
 * So while each person has an underlying cgroups, not all cgroups have a
 * corresponding person.
 *
 * Beyond this semantic difference, there is also data massaging: a
 * {@link Person} has data converted into a format that the UI can directly and
 * efficiently use, as compared to a {@link CGroupUserEntityData}, which is
 * tailored for transmission and storage.
 */
export interface Person {
    /**
     * The source of the underlying data.
     */
    type: "cgroup" | "cluster";
    /**
     * Nanoid of the underlying cgroup or {@link FaceCluster}.
     */
    id: string;
    /**
     * The name of the person.
     *
     * This will only be set for named cgroups.
     */
    name: string | undefined;
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

export type NamedPerson = Omit<Person, "name"> & {
    name: string;
};

/**
 * Construct in-memory people using the data present locally, ignoring faces
 * belonging to deleted and hidden files.
 *
 * This function is meant to run after files, cgroups and faces have been synced
 * with remote, and clustering has completed. It uses the current local state to
 * construct an in-memory list of {@link Person}s on which the UI will operate.
 *
 * @return A list of {@link Person}s, sorted by the number of files that they
 * reference.
 */
export const reconstructPeople = async (): Promise<Person[]> => {
    if (!(await wipClusterEnable())) return [];

    const files = await getLocalFiles("normal");
    const fileByID = new Map(files.map((f) => [f.id, f]));

    // "Person face"s are faces annotated with their corresponding local files.
    //
    // Note that since we ignore deleted and hidden files, it is possible that
    // there might not be an entry for a particular face in this map even if its
    // file is otherwise existent.
    const personFaceByID = new Map<
        string,
        { faceID: string; file: EnteFile; score: number }
    >();

    const faceIndexes = await getFaceIndexes();
    for (const { faces } of faceIndexes) {
        for (const { faceID, score } of faces) {
            const fileID = fileIDFromFaceID(faceID);
            if (!fileID) continue;
            const file = fileByID.get(fileID);
            if (!file) continue;
            personFaceByID.set(faceID, { faceID, file, score });
        }
    }

    // Help out tsc.
    const typeCGroup: Person["type"] = "cgroup";
    const typeCluster: Person["type"] = "cluster";

    // Convert cgroups to people.
    const cgroups = await savedCGroupUserEntities();
    const cgroupPeople = cgroups.map(({ id, data: cgroup }) => {
        // Hidden cgroups are clusters specifically marked so as to not be shown
        // in the UI.
        if (cgroup.isHidden) return undefined;

        // Person faces from all the clusters assigned to this cgroup, sorted by
        // their score.
        const faces = cgroup.assigned
            .map(({ faces }) =>
                faces.map((id) => personFaceByID.get(id)).filter((f) => !!f),
            )
            .flat()
            .sort((a, b) => b.score - a.score);

        // Ignore this cgroup if we don't have visible faces left in it.
        const highestScoringFace = faces[0];
        if (!highestScoringFace) return undefined;

        // IDs of the files containing this face.
        const fileIDs = [...new Set(faces.map((f) => f.file.id))];

        // Avatar face ID, or the highest scoring face.
        const avatarFaceID = cgroup.avatarFaceID;
        let avatarFile: EnteFile | undefined;
        if (avatarFaceID) {
            const avatarFileID = fileIDFromFaceID(avatarFaceID);
            if (avatarFileID) avatarFile = fileByID.get(avatarFileID);
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

        return {
            type: typeCGroup,
            id,
            name: cgroup.name,
            fileIDs,
            displayFaceID,
            displayFaceFile,
        };
    });

    // Convert local-only clusters to people.
    const localClusters = await savedFaceClusters();
    const clusterPeople = localClusters.map((cluster) => {
        const faces = cluster.faces
            .map((id) => personFaceByID.get(id))
            .filter((f) => !!f);

        // Ignore clusters with too few visible faces.
        if (faces.length < 10) return undefined;

        const topFace = faces.reduce((top, face) =>
            top.score > face.score ? top : face,
        );

        return {
            type: typeCluster,
            id: cluster.id,
            name: undefined,
            fileIDs: [...new Set(faces.map((f) => f.file.id))],
            displayFaceID: topFace.faceID,
            displayFaceFile: topFace.file,
        };
    });

    return cgroupPeople
        .concat(clusterPeople)
        .filter((c) => !!c)
        .sort((a, b) => b.fileIDs.length - a.fileIDs.length);
};
