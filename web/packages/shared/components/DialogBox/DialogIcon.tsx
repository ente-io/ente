import { Box } from "@mui/material";
import React from "react";

export default function DialogIcon({ icon }: { icon: React.ReactNode }) {
    return (
        <Box
            className="DialogIcon"
            sx={{
                svg: {
                    width: "48px",
                    height: "48px",
                },
                color: "stroke.muted",
            }}
        >
            {icon}
        </Box>
    );
}
