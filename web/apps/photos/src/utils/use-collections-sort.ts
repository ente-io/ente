import {
    collectionsSortBy,
    type CollectionsSortBy,
} from "ente-new/photos/services/collection-summary";
import { includes } from "ente-utils/type-guards";
import { useEffect, useState } from "react";

export const useCollectionsSortByLocalState = (
    initialValue: CollectionsSortBy,
) => {
    const key = "collectionsSortBy";

    const [value, setValue] = useState(initialValue);

    useEffect(() => {
        const value = localStorage.getItem(key);
        if (value && includes(collectionsSortBy, value)) setValue(value);
    }, []);

    const setter = (value: CollectionsSortBy) => {
        localStorage.setItem(key, value);
        setValue(value);
    };

    return [value, setter] as const;
};
