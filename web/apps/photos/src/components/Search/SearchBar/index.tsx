import { UpdateSearch } from "@/new/photos/services/search/types";
import { EnteFile } from "@/new/photos/types/file";
import { FluidContainer } from "@ente/shared/components/Container";
import SearchIcon from "@mui/icons-material/Search";
import { IconButton } from "@mui/material";
import { Collection } from "types/collection";
import { SearchInput } from "./SearchInput";
import { SearchBarWrapper, SearchMobileBox } from "./styledComponents";

interface Props {
    updateSearch: UpdateSearch;
    collections: Collection[];
    files: EnteFile[];
    isInSearchMode: boolean;
    setIsInSearchMode: (v: boolean) => void;
}

export default function SearchBar({
    setIsInSearchMode,
    isInSearchMode,
    ...props
}: Props) {
    const showSearchInput = () => setIsInSearchMode(true);

    return (
        <SearchBarWrapper>
            <SearchInput
                {...props}
                isOpen={isInSearchMode}
                setIsOpen={setIsInSearchMode}
            />
            <SearchBarMobile
                show={!isInSearchMode}
                showSearchInput={showSearchInput}
            />
        </SearchBarWrapper>
    );
}

function SearchBarMobile({ show, showSearchInput }) {
    if (!show) {
        return <></>;
    }
    return (
        <SearchMobileBox>
            <FluidContainer justifyContent="flex-end" ml={1.5}>
                <IconButton onClick={showSearchInput}>
                    <SearchIcon />
                </IconButton>
            </FluidContainer>
        </SearchMobileBox>
    );
}
