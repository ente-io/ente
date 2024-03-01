import { FluidContainer } from "@ente/shared/components/Container";
import SearchIcon from "@mui/icons-material/Search";
import { IconButton } from "@mui/material";
import { SearchMobileBox } from "./styledComponents";

export function SearchBarMobile({ show, showSearchInput }) {
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
