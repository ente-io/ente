import { styled, Theme } from '@mui/material';
import MuiAccordion, { AccordionProps } from '@mui/material/Accordion';
import MuiAccordionSummary from '@mui/material/AccordionSummary';
import MuiAccordionDetails from '@mui/material/AccordionDetails';
import { Typography, TypographyProps } from '@mui/material';

export const UploadProgressSection = styled((props: AccordionProps) => (
    <MuiAccordion disableGutters elevation={0} square {...props} />
))(({ theme }: { theme: Theme }) => ({
    borderTop: `1px solid ${theme.palette.divider}`,
    '&:last-child': {
        borderBottom: `1px solid ${theme.palette.divider}`,
    },
    '&:before': {
        display: 'none',
    },
}));

export const UploadProgressSectionTitle = styled(MuiAccordionSummary)(() => ({
    backgroundColor: 'rgba(255, 255, 255, .05)',
}));

export const UploadProgressSectionContent = styled(MuiAccordionDetails)(
    ({ theme }: { theme: Theme }) => ({
        padding: theme.spacing(2),
    })
);

export const SectionInfo = (props: TypographyProps) => (
    <Typography
        color={'text.muted'}
        variant="small"
        {...props}
        sx={{ mb: 1 }}
    />
);
