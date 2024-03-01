import { FlexWrapper } from "@ente/shared/components/Container";
import CalendarIcon from "@mui/icons-material/CalendarMonth";
import FolderIcon from "@mui/icons-material/Folder";
import ImageIcon from "@mui/icons-material/Image";
import LocationIcon from "@mui/icons-material/LocationOn";
import SearchIcon from "@mui/icons-material/SearchOutlined";
import { Box } from "@mui/material";
import { components } from "react-select";
import { SelectComponents } from "react-select/src/components";
import { SearchOption, SuggestionType } from "types/search";

const { ValueContainer } = components;

const getIconByType = (type: SuggestionType) => {
    switch (type) {
        case SuggestionType.DATE:
            return <CalendarIcon />;
        case SuggestionType.LOCATION:
        case SuggestionType.CITY:
            return <LocationIcon />;
        case SuggestionType.COLLECTION:
            return <FolderIcon />;
        case SuggestionType.FILE_NAME:
            return <ImageIcon />;
        default:
            return <SearchIcon />;
    }
};

export const ValueContainerWithIcon: SelectComponents<
    SearchOption,
    false
>["ValueContainer"] = (props) => (
    <ValueContainer {...props}>
        <FlexWrapper>
            <Box className="icon" mr={1.5} color="stroke.muted">
                {getIconByType(props.getValue()[0]?.type)}
            </Box>
            {props.children}
        </FlexWrapper>
    </ValueContainer>
);
