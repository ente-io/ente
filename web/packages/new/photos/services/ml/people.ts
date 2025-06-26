import { assertionFailed } from "ente-base/assert";
import log from "ente-base/log";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { randomSample } from "ente-utils/array";
import { computeNormalCollectionFilesFromSaved } from "../file";
import {
    savedCGroups,
    updateOrCreateUserEntities,
    type CGroup,
} from "../user-entity";
import type { FaceCluster } from "./cluster";
import { savedFaceClusters, savedFaceIndexes, saveFaceClusters } from "./db";
import { fileIDFromFaceID } from "./face";
import {
    savedRejectedClustersForCGroup,
    saveRejectedClustersForCGroup,
} from "./kvdb";
import { dotProduct } from "./math";

/**
 * A cgroup ("cluster group") is a group of clusters (possibly containing just a
 * single cluster) that the user has interacted with.
 *
 * Interactions include hiding, merging and giving a name and/or a cover photo.
 *
 * The most frequent interaction is naming a {@link FaceCluster}, which promotes
 * it to a become a {@link CGroup}. The promotion comes with the
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
     * An unordered set of clusters that have been assigned to this group.
     *
     * For ease of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    assigned: FaceCluster[];
    /**
     * An unordered set of faces (IDs) that the user has manually marked as not
     * belonging to this group.
     *
     * For ease of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    rejectedFaceIDs: string[];
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
     * - {@link avatarFaceID} is the face selected by the user.
     *
     * - {@link displayFaceID} is the automatic placeholder, and only comes into
     *   effect if the user has not explicitly selected a face.
     *
     * Also, see: [Note: Mark optional for Zod/exactOptionalPropertyTypes]
     */
    avatarFaceID?: string | undefined;
}

/**
 * A massaged version of {@link CGroup} or a {@link FaceCluster} suitable for
 * being shown in the UI.
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
 * efficiently use, as compared to a {@link CGroup}, which is tailored for
 * transmission and storage.
 */
export type Person = (
    | { type: "cgroup"; cgroup: CGroup; isHidden: boolean }
    | { type: "cluster"; cluster: FaceCluster }
) & {
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
};

/**
 * A person of type "cgroup".
 */
export type CGroupPerson = Exclude<Person, { type: "cluster" }>;

/**
 * A person of type "cluster".
 */
export type ClusterPerson = Exclude<Person, { type: "cgroup" }>;

/**
 * A {@link Person} whose name is not empty.
 */
export type NamedPerson = Person & { name: string };

/**
 * A face ID annotated with the {@link EnteFile} that contains it.
 *
 * Both these pieces of information are needed for a UI element to show the
 * face.
 */
export interface PreviewableFace {
    /** The ID of the face to display. */
    faceID: string;
    /** The {@link EnteFile} which contains this face. */
    file: EnteFile;
}

/**
 * Pre-computed in-memory state for UI that deals with people.
 */
export interface PeopleState {
    /**
     * List of all people.
     *
     * The list is sorted such that named people are first, then the local only
     * unnamed clusters. Within each section, people are sorted by the number of
     * files that they reference.
     */
    people: Person[];
    /**
     * List of all people who should be normally shown in the UI.
     *
     * By default, people derived from small, local-only clusters are not
     * surfaced in the UI. Such people will be present in the {@link people}
     * list, but not in the {@link visiblePeople} list. The user can still see
     * these people by clicking on one of the faces they contain from a photo's
     * info view.
     */
    visiblePeople: Person[];
    /**
     * faceID => person
     *
     * {@link people}, but indexed by face (ids).
     */
    personByFaceID: Map<string, Person>;
}

/**
 * Construct an in-memory people state using the data present locally, ignoring
 * faces belonging to deleted and hidden files.
 *
 * This function is meant to run after files, cgroups and faces have been synced
 * with remote, and clustering has completed. It uses the current local state to
 * construct an in-memory list of {@link Person}s on which the UI will operate.
 */
export const reconstructPeopleState = async (): Promise<PeopleState> => {
    const normalCollectionFiles = await computeNormalCollectionFilesFromSaved();
    const fileByID = new Map(normalCollectionFiles.map((f) => [f.id, f]));

    // "Person face"s are faces annotated with their corresponding local files.
    //
    // Note that since we ignore deleted and hidden files, it is possible that
    // there might not be an entry for a particular face in this map even if its
    // file is otherwise existent.
    const personFaceByID = new Map<
        string,
        { faceID: string; file: EnteFile; score: number }
    >();

    const faceIndexes = await savedFaceIndexes();
    for (const { faces } of faceIndexes) {
        for (const { faceID, score } of faces) {
            const fileID = fileIDFromFaceID(faceID);
            if (!fileID) continue;
            const file = fileByID.get(fileID);
            if (!file) continue;
            personFaceByID.set(faceID, { faceID, file, score });
        }
    }

    // Return annotated "person faces" corresponding to the given face ids,
    // sorting them by the creation time of the file they belong to.
    //
    // Within the same file, sort by the face score.
    const personFacesSortedNewestFirst = (faceIDs: string[]) =>
        faceIDs
            .map((faceID) => personFaceByID.get(faceID))
            .filter((pf) => !!pf)
            .sort((a, b) => {
                const at = fileCreationTime(a.file);
                const bt = fileCreationTime(b.file);
                return bt == at ? b.score - a.score : bt - at;
            });

    // Help out tsc.
    type Interim = (Person | undefined)[];

    // Convert cgroups to people.
    const cgroups = await savedCGroups();
    const cgroupPeople: Interim = cgroups.map((cgroup) => {
        const { id, data } = cgroup;
        const { name, assigned } = data;

        let isHidden = data.isHidden;

        // Older versions of the mobile app marked hidden cgroups by setting
        // their name to an empty string.
        if (!name) isHidden = true;

        let assignedFaceIDs: string[][];
        if (data.rejectedFaceIDs.length == 0) {
            // Fast path for when there are no rejected faces.
            assignedFaceIDs = assigned.map(({ faces }) => faces);
        } else {
            const rejectedFaceIDs = new Set(data.rejectedFaceIDs);
            assignedFaceIDs = assigned.map(({ faces }) =>
                faces.filter((id) => !rejectedFaceIDs.has(id)),
            );
        }

        // Person faces from all the clusters assigned to this cgroup, sorted by
        // recency (then score).
        const faces = personFacesSortedNewestFirst(assignedFaceIDs.flat());

        // Ignore this cgroup if we don't have visible faces left in it.
        const mostRecentFace = faces[0];
        if (!mostRecentFace) return undefined;

        // IDs of the files containing this face.
        const fileIDs = [...new Set(faces.map((f) => f.file.id))];

        // Avatar face ID, or the highest scoring face.
        let avatarFile: EnteFile | undefined;
        const avatarFaceID = resolvedAvatarFaceID(data.avatarFaceID);
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
            displayFaceID = mostRecentFace.faceID;
            displayFaceFile = mostRecentFace.file;
        }

        return {
            type: "cgroup",
            cgroup,
            id,
            name,
            fileIDs,
            displayFaceID,
            displayFaceFile,
            isHidden,
        };
    });

    // Convert local-only clusters to people.
    const localClusters = await savedFaceClusters();
    const clusterPeople: Interim = localClusters.map((cluster) => {
        const faces = personFacesSortedNewestFirst(cluster.faces);

        // Ignore this cluster if we don't have visible faces left in it.
        const mostRecentFace = faces[0];
        if (!mostRecentFace) return undefined;

        return {
            type: "cluster",
            cluster,
            id: cluster.id,
            name: undefined,
            fileIDs: [...new Set(faces.map((f) => f.file.id))],
            displayFaceID: mostRecentFace.faceID,
            displayFaceFile: mostRecentFace.file,
        };
    });

    const sorted = (ps: Interim) =>
        ps
            .filter((c) => !!c)
            .sort((a, b) => b.fileIDs.length - a.fileIDs.length);

    const people = sorted(cgroupPeople).concat(sorted(clusterPeople));

    const visiblePeople = people.filter((p) => {
        switch (p.type) {
            case "cgroup":
                // Hidden cgroups are clusters specifically marked so as to not
                // be shown in the UI. The user can still see them from within
                // file info if they wish.
                if (p.isHidden) return false;
                break;

            case "cluster":
                // Ignore local only clusters with too few visible faces.
                if (p.cluster.faces.length < 10) return false;
                break;
        }

        // Show it.
        return true;
    });

    // Reverse map for easy lookup.
    const personByFaceID = new Map<string, Person>();
    for (const person of people) {
        const faceIDs =
            person.type == "cgroup"
                ? person.cgroup.data.assigned.map((c) => c.faces).flat()
                : person.cluster.faces;
        for (const faceID of faceIDs) {
            personByFaceID.set(faceID, person);
        }
    }

    return { people, visiblePeople, personByFaceID };
};

/**
 * Older versions of the mobile app set the avatarFileID as the avatarFaceID.
 * Use the format of the string to detect such cases, and as a workaround,
 * ignore the avatarID in such cases.
 */
const resolvedAvatarFaceID = (avatarFaceID: string | undefined) =>
    avatarFaceID?.split("_").length == 1 ? undefined : avatarFaceID;

/**
 * Return only those from amongst {@link people} that have a name defined.
 *
 * @param people List of all people, named and unnamed.
 */
export const filterNamedPeople = (people: Person[]): NamedPerson[] => {
    const namedPeople: NamedPerson[] = [];
    for (const person of people) {
        const name = person.name;
        if (name) {
            namedPeople.push({ ...person, name });
        }
    }
    return namedPeople;
};

export type PreviewableCluster = FaceCluster & {
    /**
     * A list of up to 3 "preview" faces for the cluster, each annotated with
     * the corresponding {@link EnteFile} that contains them.
     */
    previewFaces: PreviewableFace[];
};

export interface PersonSuggestionsAndChoices {
    /**
     * Previously saved choices.
     *
     * These are clusters (sorted by size) that the user had previously assigned
     * to or explicitly rejected from the person under consideration.
     *
     * The {@link assigned} flag will true for the entries that correspond to
     * assigned clusters, and false for those that the user had rejected.
     *
     * This array is guaranteed to be non-empty, and it is guaranteed that the
     * first item is a merged cluster (i.e. a cluster for which assigned is
     * true), even if there exists an ignored cluster with a larger size. The
     * rest of the entries are intermixed and sorted by size normally.
     *
     * For convenience of the UI, the first entry will have also have the
     * {@link fixed} flag set.
     */
    choices: (PreviewableCluster & { fixed?: boolean; assigned: boolean })[];
    /**
     * New suggestions to offer to the user.
     */
    suggestions: PreviewableCluster[];
}

/**
 * Returns suggestions and existing choices for the given person.
 */
export const _suggestionsAndChoicesForPerson = async (
    person: CGroupPerson,
): Promise<PersonSuggestionsAndChoices> => {
    const startTime = Date.now();

    const rejectedFaceIDs = new Set(person.cgroup.data.rejectedFaceIDs);
    const personClusters = person.cgroup.data.assigned.map((cluster) => ({
        ...cluster,
        faces: cluster.faces.filter((id) => !rejectedFaceIDs.has(id)),
    }));

    const rejectedClusterIDs = new Set(
        await savedRejectedClustersForCGroup(person.cgroup.id),
    );

    const localClusters = await savedFaceClusters();
    const faceIndexes = await savedFaceIndexes();

    const embeddingByFaceID = new Map(
        faceIndexes
            .map(({ faces }) =>
                faces.map(
                    (f) => [f.faceID, new Float32Array(f.embedding)] as const,
                ),
            )
            .flat(),
    );

    const personFaceEmbeddings = personClusters
        .map(({ faces }) => faces.map((id) => embeddingByFaceID.get(id)))
        .flat()
        .filter((e) => !!e);

    // Randomly sample faces to limit the O(n^2) cost.
    const sampledPersonEmbeddings = randomSample(personFaceEmbeddings, 50);

    const candidateClustersAndSimilarity: [FaceCluster, number][] = [];
    const rejectedClusters: FaceCluster[] = [];
    for (const cluster of localClusters) {
        const { id, faces } = cluster;

        // User has explicitly asked us to ignore this cluster. Add it to the
        // list of rejected clusters that we return to the UI for listing out.
        // Keep this check first so that we pick these up even if we get e.g.
        // singleton clusters from remote.
        if (rejectedClusterIDs.has(id)) {
            rejectedClusters.push(cluster);
            continue;
        }

        // Ignore singleton clusters.
        if (faces.length < 2) continue;

        const sampledOtherEmbeddings = randomSample(faces, 50)
            .map((id) => embeddingByFaceID.get(id))
            .filter((e) => !!e);

        // Sort all cosine similarities pairs, and consider their median.
        const csims: number[] = [];
        for (const other of sampledOtherEmbeddings) {
            for (const embedding of sampledPersonEmbeddings) {
                csims.push(dotProduct(embedding, other));
            }
        }
        csims.sort();

        if (csims.length == 0) continue;

        const medianSim = csims[Math.floor(csims.length / 2)]!;
        if (medianSim > 0.48) {
            candidateClustersAndSimilarity.push([cluster, medianSim]);
        }
    }

    // Sort suggestions by the (median) cosine similarity.
    candidateClustersAndSimilarity.sort(([, a], [, b]) => b - a);
    const suggestedClusters = candidateClustersAndSimilarity.map(([c]) => c);

    // Annotate the clusters with the information that the UI needs to show its
    // preview faces.
    const normalCollectionFiles = await computeNormalCollectionFilesFromSaved();
    const fileByID = new Map(normalCollectionFiles.map((f) => [f.id, f]));

    const toPreviewable = (cluster: FaceCluster) => {
        const previewFaces: PreviewableFace[] = [];
        for (const faceID of cluster.faces) {
            const fileID = fileIDFromFaceID(faceID);
            if (!fileID) {
                assertionFailed();
                continue;
            }

            const file = fileByID.get(fileID);
            if (!file) {
                // This might be a hidden/trash file, and it is thus not
                // appropriate to use it as a preview file anyway.
                continue;
            }

            previewFaces.push({ file, faceID });

            if (previewFaces.length == 4) break;
        }

        if (previewFaces.length == 0) return undefined;

        return { ...cluster, previewFaces };
    };

    const toPreviewableList = (clusters: FaceCluster[]) =>
        clusters.map(toPreviewable).filter((p) => !!p);

    const sortBySize = (entries: { faces: unknown[] }[]) =>
        entries.sort((a, b) => b.faces.length - a.faces.length);

    const assignedChoices = toPreviewableList(personClusters).map((p) => ({
        ...p,
        assigned: true,
    }));

    sortBySize(assignedChoices);

    const rejectedChoices = toPreviewableList(rejectedClusters).map((p) => ({
        ...p,
        assigned: false,
    }));

    // Ensure that the first item in the choices is not an ignored one, even if
    // that is what we'd have ended up with if we sorted by size.

    const firstChoice = { ...assignedChoices[0]!, fixed: true };
    const restChoices = assignedChoices.slice(1).concat(rejectedChoices);
    sortBySize(restChoices);

    const choices = [firstChoice, ...restChoices];

    // Limit to the number of suggestions shown in a single go.
    const suggestions = toPreviewableList(suggestedClusters.slice(0, 80));

    log.info(
        `Generated ${suggestions.length} suggestions for ${person.id} (${Date.now() - startTime} ms)`,
    );

    return { choices, suggestions };
};

/**
 * A map specifying the changes to make when the user presses the save button on
 * the people suggestions dialog.
 *
 * Each entry is a (clusterID, update) pair.
 *
 * * Clusters with "assign" should be assigned to the cgroup,
 * * Clusters with "rejectSuggestion" should be rejected from the cgroup
 *   locally. These correspond to suggestions which the user did not accept.
 * * Clusters with "rejectSavedChoice" should be rejected from the cgroup both
 *   locally and on remote. These correspond to saved choices which the user
 *   went on to explicitly reject.
 * * Clusters with "reset" should be reset - i.e. should be removed from both
 *   the assigned and rejected choices associated with the cgroup (if needed).
 */
export type PersonSuggestionUpdates = Map<
    string,
    "assign" | "rejectSuggestion" | "rejectSavedChoice" | "reset"
>;

/**
 * Implementation for the "save" action on the SuggestionsDialog.
 *
 * This function modifies remote and local state to reflect the given
 * {@link updates} for {@link cgroup}.
 *
 * @param cgroup The cgroup that we want to update.
 *
 * @param updates The changes to make. See {@link PersonSuggestionUpdates}.
 *
 * @param masterKey The user's masterKey (as a base64 string), which is is used
 * to encrypt and decrypt the entity key associated with cgroups.
 */
export const _applyPersonSuggestionUpdates = async (
    cgroup: CGroup,
    updates: PersonSuggestionUpdates,
    masterKey: string,
) => {
    const localClusters = await savedFaceClusters();

    let assignedClusters = [...cgroup.data.assigned];
    let rejectedClusterIDs = await savedRejectedClustersForCGroup(cgroup.id);
    let newlyRejectedFaceIDs: string[] = [];

    let assignUpdateCount = 0;
    let rejectUpdateCount = 0;

    const clusterWithID = (clusterID: string) =>
        localClusters.find((c) => c.id == clusterID)!;

    // Add cluster with `clusterID` to the list of assigned clusters.
    const assign = (clusterID: string) => {
        const cluster = clusterWithID(clusterID);
        assignedClusters.push(cluster);
        assignUpdateCount += 1;
    };

    // Remove cluster with `clusterID` from the list of assigned clusters (if
    // needed).
    const unassignIfNeeded = (clusterID: string) => {
        if (assignedClusters.find(({ id }) => id == clusterID)) {
            const [updatedAssignedClusters, cluster] = assignedClusters.reduce<
                [FaceCluster[], FaceCluster | undefined]
            >(
                ([clusters, foundCluster], c) => {
                    if (c.id == clusterID) return [clusters, c];
                    clusters.push(c);
                    return [clusters, foundCluster];
                },
                [[], undefined],
            );

            assignedClusters = updatedAssignedClusters;
            assignUpdateCount += 1;
            // Prior to this, this cluster was not saved locally since it was
            // part of the remote data. Since we're removing it from the remote
            // state, add it to the local state instead so that the user can see
            // it in their saved choices (local only).
            localClusters.push(cluster!);
        }
    };

    // Add `clusterID` to the list of rejected clusters locally.
    const rejectClusterLocal = (clusterID: string) => {
        rejectedClusterIDs.push(clusterID);
        rejectUpdateCount += 1;
    };

    // Mark the faces in `clusterID` as rejected on remote.
    const rejectFacesRemote = (clusterID: string) => {
        const cluster = clusterWithID(clusterID);
        newlyRejectedFaceIDs = newlyRejectedFaceIDs.concat(cluster.faces);
    };

    // Remove `clusterID` from the list of rejected clusters (if needed).
    const unrejectIfNeeded = (clusterID: string) => {
        if (rejectedClusterIDs.includes(clusterID)) {
            rejectedClusterIDs = rejectedClusterIDs.filter(
                (id) => id != clusterID,
            );
            rejectUpdateCount += 1;
        }
    };

    for (const [clusterID, assigned] of updates.entries()) {
        switch (assigned) {
            case "assign":
                assign(clusterID);
                unrejectIfNeeded(clusterID);
                break;

            case "rejectSuggestion":
                unassignIfNeeded(clusterID);
                rejectClusterLocal(clusterID);
                break;

            case "rejectSavedChoice":
                unassignIfNeeded(clusterID);
                rejectClusterLocal(clusterID);
                rejectFacesRemote(clusterID);
                break;

            case "reset":
                unassignIfNeeded(clusterID);
                unrejectIfNeeded(clusterID);
                break;
        }
    }

    if (assignUpdateCount > 0 || newlyRejectedFaceIDs.length > 0) {
        const assigned = assignedClusters;
        const rejectedFaceIDs =
            cgroup.data.rejectedFaceIDs.concat(newlyRejectedFaceIDs);
        await updateOrCreateUserEntities(
            "cgroup",
            [
                {
                    ...cgroup,
                    data: { ...cgroup.data, assigned, rejectedFaceIDs },
                },
            ],
            masterKey,
        );
        await saveFaceClusters(localClusters);
    }

    if (rejectUpdateCount > 0) {
        await saveRejectedClustersForCGroup(cgroup.id, rejectedClusterIDs);
    }

    log.info(
        `Updated ${assignUpdateCount} assigns and ${rejectUpdateCount} rejects for ${cgroup.id}`,
    );
};
