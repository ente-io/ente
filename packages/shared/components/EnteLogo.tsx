import { styled } from "@mui/material";

const LogoImage = styled("img")`
    margin: 3px 0;
    pointer-events: none;
`;

export function EnteLogo(props) {
    return (
        <LogoImage height={18} alt="logo" src="/images/ente.svg" {...props} />
    );
}
