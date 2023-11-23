import React, { useContext } from 'react';
import { PeopleList } from 'components/MachineLearning/PeopleList';
import { IndexStatus } from 'types/machineLearning/ui';
import { SuggestionType, Suggestion } from 'types/search';
import { components } from 'react-select';
import { Row } from '@ente/shared/components/Container';
import { Col } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import styled from '@mui/styled-engine';
import { t } from 'i18next';

const { Menu } = components;

const LegendRow = styled(Row)`
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0px;
`;

const Legend = styled('span')`
    font-size: 20px;
    color: #ddd;
    display: inline;
`;

const Caption = styled('span')`
    font-size: 12px;
    display: inline;
    padding: 8px 12px;
`;

const MenuWithPeople = (props) => {
    const appContext = useContext(AppContext);
    // addLogLine("props.selectProps.options: ", selectRef);
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
            <Col>
                {((appContext.mlSearchEnabled && indexStatus) ||
                    (people && people.length > 0)) && (
                    <LegendRow>
                        <Legend>{t('PEOPLE')}</Legend>
                    </LegendRow>
                )}
                {appContext.mlSearchEnabled && indexStatus && (
                    <LegendRow>
                        <Caption>{indexStatusSuggestion.label}</Caption>
                    </LegendRow>
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
            </Col>
            {props.children}
        </Menu>
    );
};

export default MenuWithPeople;
