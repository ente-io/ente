import { Dispatch, SetStateAction, useEffect, useState } from 'react';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';

export function useLocalState<T>(
    key: LS_KEYS,
    initialValue?: T
): [T, Dispatch<SetStateAction<T>>] {
    const [value, setValue] = useState<T>(null);

    useEffect(() => {
        const { value } = getData(key) ?? {};
        setValue(value ?? initialValue);
    }, []);

    useEffect(() => {
        setData(key, { value });
    }, [value]);

    return [value, setValue];
}
