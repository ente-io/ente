import { Typography, TypographyProps, styled } from "@mui/material";
import MuiAccordion, { AccordionProps } from "@mui/material/Accordion";
import MuiAccordionDetails from "@mui/material/AccordionDetails";
import MuiAccordionSummary from "@mui/material/AccordionSummary";

export const UploadProgressSection = styled((props: AccordionProps) => (
    <MuiAccordion disableGutters elevation={0} square {...props} />
))(({ theme }) => ({
    borderTop: `1px solid ${theme.palette.divider}`,
    "&:last-child": {
        borderBottom: `1px solid ${theme.palette.divider}`,
    },
    "&:before": {
        display: "none",
    },
}));

export const UploadProgressSectionTitle = styled(MuiAccordionSummary)(() => ({
    backgroundColor: "rgba(255, 255, 255, .05)",
}));

export const UploadProgressSectionContent = styled(MuiAccordionDetails)(
    ({ theme }) => ({
        padding: theme.spacing(2),
    }),
);

export const SectionInfo = (props: TypographyProps) => (
    <Typography
        color={"text.muted"}
        variant="small"
        {...props}
        sx={{ mb: 1 }}
    />
);
