import React, { useContext } from 'react';
import { PeopleList } from 'components/MachineLearning/PeopleList';
import { Legend } from 'components/PhotoSwipe/styledComponents/Legend';
import { IndexStatus } from 'types/machineLearning/ui';
import { SuggestionType, Suggestion } from 'types/search';
import { components } from 'react-select';
import { Row } from 'components/Container';
import { Col } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import styled from '@mui/styled-engine';
import constants from 'utils/strings/constants';

const { Menu } = components;

const LegendRow = styled(Row)`
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0px;
`;

const Caption = styled('span')`
    font-size: 12px;
    display: inline;
    padding: 8px 12px;
`;

const MenuWithPeople = (props) => {
    const appContext = useContext(AppContext);
    // console.log("props.selectProps.options: ", selectRef);
    const peopleSuggestions = props.selectProps.options.filter(
        (o) => o.type === SuggestionType.PERSON
    );
    const people = peopleSuggestions.map((o) => o.value);

    const indexStatusSuggestion = props.selectProps.options.filter(
        (o) => o.type === SuggestionType.INDEX_STATUS
    )[0] as Suggestion;

    const indexStatus = indexStatusSuggestion?.value as IndexStatus;

    return (
        <Menu {...props}>
            {appContext.mlSearchEnabled && (
                <Col>
                    <LegendRow>
                        <Legend>{constants.PEOPLE}</Legend>
                        {indexStatus && (
                            <Caption>{indexStatusSuggestion.label}</Caption>
                        )}
                    </LegendRow>
                    {people && people.length > 0 && (
                        <Row>
                            <PeopleList
                                people={people}
                                maxRows={2}
                                onSelect={(person, index) => {
                                    props.selectRef.current.blur();
                                    props.setValue(peopleSuggestions[index]);
                                }}></PeopleList>
                        </Row>
                    )}
                </Col>
            )}
            {props.children}
        </Menu>
    );
};

export default MenuWithPeople;
