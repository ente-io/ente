import { LinearProgress, styled } from "@mui/material";
import { DotSeparator } from "../styledComponents";

export const Progressbar = styled(LinearProgress)(() => ({
    ".MuiLinearProgress-bar": {
        borderRadius: "2px",
    },
    borderRadius: "2px",
    backgroundColor: "rgba(255, 255, 255, 0.2)",
}));

Progressbar.defaultProps = {
    variant: "determinate",
};

export const LegendIndicator = styled(DotSeparator)`
    font-size: 8.71px;
    margin: 0;
    margin-right: 4px;
    color: inherit;
`;
