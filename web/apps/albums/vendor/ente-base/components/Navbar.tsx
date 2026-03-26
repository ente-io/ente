import { styled } from "@mui/material";

export const NavbarBase = styled("div")(
    ({ theme }) => `
    flex: 0 0 64px;
    display: flex;
    justify-content: center;
    align-items: center;
    border-bottom: 1px solid ${theme.vars.palette.divider};
`,
);
