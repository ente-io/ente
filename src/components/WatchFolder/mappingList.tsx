import React from 'react';
import { MappingEntry } from './mappingEntry';
import { MappingsContainer } from './styledComponents';
export function MappingList({ mappings, handleRemoveWatchMapping }) {
    return (
        <MappingsContainer>
            {mappings.map((mapping) => {
                console.log(mapping);
                return (
                    <MappingEntry
                        key={mapping.collectionName}
                        mapping={mapping}
                        handleRemoveMapping={handleRemoveWatchMapping}
                    />
                );
            })}
        </MappingsContainer>
    );
}
