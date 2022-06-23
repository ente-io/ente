import React from 'react';
import { WatchMapping } from 'types/watchFolder';
import { MappingEntry } from './mappingEntry';
import { MappingsContainer } from './styledComponents';
interface Iprops {
    mappings: WatchMapping[];
    handleRemoveWatchMapping: (value: WatchMapping) => void;
}

export function MappingList({ mappings, handleRemoveWatchMapping }: Iprops) {
    return (
        <MappingsContainer>
            {mappings.map((mapping) => {
                return (
                    <MappingEntry
                        key={mapping.rootFolderName}
                        mapping={mapping}
                        handleRemoveMapping={handleRemoveWatchMapping}
                    />
                );
            })}
        </MappingsContainer>
    );
}
