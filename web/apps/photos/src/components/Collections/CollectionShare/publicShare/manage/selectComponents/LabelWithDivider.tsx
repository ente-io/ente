import { Box, Divider, Typography } from "@mui/material";

export function LabelWithDivider({ data }) {
    return (
        <>
            <Box className="main" px={3} py={1}>
                <Typography>{data.label}</Typography>
            </Box>
            <Divider sx={{ borderColor: "stroke.fainter" }} />
        </>
    );
}
