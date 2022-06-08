import styled from 'styled-components';

export const ManageSectionLabel = styled.summary(
    ({ theme }) => `
    text-align: center;
    margin-bottom:${theme.spacing(1)};
`
);

export const ManageSectionOptions = styled.section(
    ({ theme }) => `
    margin-bottom:${theme.spacing(4)};
`
);
