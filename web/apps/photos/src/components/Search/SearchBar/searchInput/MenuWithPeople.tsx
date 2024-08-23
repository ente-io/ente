import { PeopleList } from "@/new/photos/components/PeopleList";
import { isMLEnabled } from "@/new/photos/services/ml";
import { Row } from "@ente/shared/components/Container";
import { Box, styled } from "@mui/material";
import { t } from "i18next";
import { components } from "react-select";
import { Suggestion, SuggestionType } from "types/search";

const { Menu } = components;

const Legend = styled("span")`
    font-size: 20px;
    color: #ddd;
    display: inline;
    padding: 0px 12px;
`;

const Caption = styled("span")`
    font-size: 12px;
    display: inline;
    padding: 0px 12px;
`;

const MenuWithPeople = (props) => {
    // log.info("props.selectProps.options: ", selectRef);
    const peopleSuggestions = props.selectProps.options.filter(
        (o) => o.type === SuggestionType.PERSON,
    );
    const people = peopleSuggestions.map((o) => o.value);

    const indexStatusSuggestion = props.selectProps.options.filter(
        (o) => o.type === SuggestionType.INDEX_STATUS,
    )[0] as Suggestion;

    const indexStatus = indexStatusSuggestion?.value;
    return (
        <Menu {...props}>
            <Box my={1}>
                {isMLEnabled() &&
                    indexStatus &&
                    (people && people.length > 0 ? (
                        <Box>
                            <Legend>{t("PEOPLE")}</Legend>
                        </Box>
                    ) : (
                        <Box height={6} />
                    ))}

                {isMLEnabled() && indexStatus && (
                    <Box>
                        <Caption>{indexStatusSuggestion.label}</Caption>
                    </Box>
                )}
                {people && people.length > 0 && (
                    <Row>
                        <PeopleList
                            people={people}
                            maxRows={2}
                            onSelect={(_, index) => {
                                props.selectRef.current.blur();
                                props.setValue(peopleSuggestions[index]);
                            }}
                        />
                    </Row>
                )}
            </Box>
            {props.children}
        </Menu>
    );
};

export default MenuWithPeople;
