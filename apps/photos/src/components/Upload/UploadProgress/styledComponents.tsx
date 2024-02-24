import { styled } from "@mui/material";
export const NotUploadSectionHeader = styled("div")(
    ({ theme }) => `
    text-align: center;
    color: ${theme.colors.danger.A700};
    border-bottom: 1px solid ${theme.colors.danger.A700};
    margin:${theme.spacing(3, 2, 1)}
`,
);

export const InProgressItemContainer = styled("div")`
    display: inline-block;
    & > span {
        display: inline-block;
    }
    & > span:first-of-type {
        position: relative;
        top: 5px;
        max-width: 340px;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }
    & > .separator {
        margin: 0 5px;
    }
`;

export const ResultItemContainer = styled("div")`
    position: relative;
    top: 5px;
    display: inline-block;
    max-width: 394px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
`;
