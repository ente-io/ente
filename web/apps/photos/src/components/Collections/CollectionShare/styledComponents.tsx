import { styled } from "@mui/material";
export const ManageSectionLabel = styled("summary")(
    ({ theme }) => `
    text-align: center;
    margin-bottom:${theme.spacing(1)};
`,
);

export const ManageSectionOptions = styled("section")(
    ({ theme }) => `
    margin-bottom:${theme.spacing(4)};
`,
);
