import { WatchMapping } from "types/watchFolder";
import { MappingEntry } from "../mappingEntry";
import { MappingsContainer } from "../styledComponents";
import { NoMappingsContent } from "./noMappingsContent/noMappingsContent";
interface Iprops {
    mappings: WatchMapping[];
    handleRemoveWatchMapping: (value: WatchMapping) => void;
}

export function MappingList({ mappings, handleRemoveWatchMapping }: Iprops) {
    return mappings.length === 0 ? (
        <NoMappingsContent />
    ) : (
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
