import CircleIcon from "@mui/icons-material/Circle";
import { LinearProgress, styled } from "@mui/material";

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

const DotSeparator = styled(CircleIcon)`
    font-size: 4px;
    margin: 0 ${({ theme }) => theme.spacing(1)};
    color: inherit;
`;

export const LegendIndicator = styled(DotSeparator)`
    font-size: 8.71px;
    margin: 0;
    margin-right: 4px;
    color: inherit;
`;
