import type { SelectionContext } from "@/new/photos/components/gallery";
import type { GalleryBarMode } from "@/new/photos/components/gallery/reducer";
import { SetSelectedState } from "types/gallery";

export const handleSelectCreator =
    (
        setSelected: SetSelectedState,
        mode: GalleryBarMode | undefined,
        userID: number | undefined,
        activeCollectionID: number,
        activePersonID: string | undefined,
        setRangeStart?,
    ) =>
    ({ id, ownerID }: { id: number; ownerID: number }, index?: number) =>
    (checked: boolean) => {
        if (typeof index !== "undefined") {
            if (checked) {
                setRangeStart(index);
            } else {
                setRangeStart(undefined);
            }
        }
        setSelected((selected) => {
            if (!mode) {
                // Retain older behavior for non-gallery call sites.
                if (selected.collectionID !== activeCollectionID) {
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context: undefined,
                    };
                }
            } else if (!selected.context) {
                // Gallery will specify a mode, but a fresh selection starts off
                // without a context, so fill it in with the current context.
                selected = {
                    ...selected,
                    context:
                        mode == "people"
                            ? { mode, personID: activePersonID! }
                            : {
                                  mode,
                                  collectionID: activeCollectionID!,
                              },
                };
            } else {
                // Both mode and context are defined.
                if (selected.context.mode != mode) {
                    // Clear selection if mode has changed.
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context:
                            mode == "people"
                                ? { mode, personID: activePersonID! }
                                : {
                                      mode,
                                      collectionID: activeCollectionID!,
                                  },
                    };
                } else {
                    if (selected.context?.mode == "people") {
                        if (selected.context.personID != activePersonID) {
                            // Clear selection if person has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    personID: activePersonID!,
                                },
                            };
                        }
                    } else {
                        if (
                            selected.context.collectionID != activeCollectionID
                        ) {
                            // Clear selection if collection has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    collectionID: activeCollectionID!,
                                },
                            };
                        }
                    }
                }
            }

            const newContext: SelectionContext | undefined = !mode
                ? undefined
                : mode == "people"
                  ? { mode, personID: activePersonID! }
                  : { mode, collectionID: activeCollectionID! };

            const handleCounterChange = (count: number) => {
                if (selected[id] === checked) {
                    return count;
                }
                if (checked) {
                    return count + 1;
                } else {
                    return count - 1;
                }
            };

            const handleAllCounterChange = () => {
                if (ownerID === userID) {
                    return {
                        ownCount: handleCounterChange(selected.ownCount),
                        count: handleCounterChange(selected.count),
                    };
                } else {
                    return {
                        count: handleCounterChange(selected.count),
                    };
                }
            };
            return {
                ...selected,
                [id]: checked,
                collectionID: activeCollectionID,
                context: newContext,
                ...handleAllCounterChange(),
            };
        });
    };

// TODO: This is a copy of handleSelectCreator, forked to
// handle multiple selections efficiently ("Select all in a single day"). If
// the code doesn't diverge, we'll have verbatim duplication.
export const handleSelectCreatorMulti =
    (
        setSelected: SetSelectedState,
        mode: GalleryBarMode | undefined,
        userID: number | undefined,
        activeCollectionID: number,
        activePersonID: string | undefined,
    ) =>
    ({ id, ownerID }: { id: number; ownerID: number }) =>
    (checked: boolean) => {
        setSelected((selected) => {
            if (!mode) {
                // Retain older behavior for non-gallery call sites.
                if (selected.collectionID !== activeCollectionID) {
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context: undefined,
                    };
                }
            } else if (!selected.context) {
                // Gallery will specify a mode, but a fresh selection starts off
                // without a context, so fill it in with the current context.
                selected = {
                    ...selected,
                    context:
                        mode == "people"
                            ? { mode, personID: activePersonID! }
                            : {
                                  mode,
                                  collectionID: activeCollectionID!,
                              },
                };
            } else {
                // Both mode and context are defined.
                if (selected.context.mode != mode) {
                    // Clear selection if mode has changed.
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context:
                            mode == "people"
                                ? { mode, personID: activePersonID! }
                                : {
                                      mode,
                                      collectionID: activeCollectionID!,
                                  },
                    };
                } else {
                    if (selected.context?.mode == "people") {
                        if (selected.context.personID != activePersonID) {
                            // Clear selection if person has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    personID: activePersonID!,
                                },
                            };
                        }
                    } else {
                        if (
                            selected.context.collectionID != activeCollectionID
                        ) {
                            // Clear selection if collection has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    collectionID: activeCollectionID!,
                                },
                            };
                        }
                    }
                }
            }

            const newContext: SelectionContext | undefined = !mode
                ? undefined
                : mode == "people"
                  ? { mode, personID: activePersonID! }
                  : { mode, collectionID: activeCollectionID! };

            const handleCounterChange = (count: number) => {
                if (selected[id] === checked) {
                    return count;
                }
                if (checked) {
                    return count + 1;
                } else {
                    return count - 1;
                }
            };

            const handleAllCounterChange = () => {
                if (ownerID === userID) {
                    return {
                        ownCount: handleCounterChange(selected.ownCount),
                        count: handleCounterChange(selected.count),
                    };
                } else {
                    return {
                        count: handleCounterChange(selected.count),
                    };
                }
            };
            return {
                ...selected,
                [id]: checked,
                collectionID: activeCollectionID,
                context: newContext,
                ...handleAllCounterChange(),
            };
        });
    };
