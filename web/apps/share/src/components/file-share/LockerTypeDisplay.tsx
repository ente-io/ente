import { Box } from "@mui/material";
import React from "react";
import type { LockerInfoData } from "../../types/file-share";
import { CopyableField } from "./CopyableField";

interface LockerTypeDisplayProps {
    type: string;
    data: LockerInfoData;
    onCopy: (value: string) => void;
}

export const LockerTypeDisplay: React.FC<LockerTypeDisplayProps> = ({
    type,
    data,
    onCopy,
}) => {
    return (
        <Box
            sx={{
                width: "100%",
                mt: 2,
                display: "flex",
                flexDirection: "column",
                gap: 2,
            }}
        >
            {type === "note" && (
                <>
                    {data.content && (
                        <CopyableField
                            value={data.content}
                            onCopy={onCopy}
                            multiline
                        />
                    )}
                </>
            )}

            {type === "physicalRecord" && (
                <>
                    {data.location && (
                        <CopyableField
                            label="Location"
                            value={data.location}
                            onCopy={onCopy}
                        />
                    )}
                    {data.notes && (
                        <CopyableField
                            label="Notes"
                            value={data.notes}
                            onCopy={onCopy}
                            multiline
                        />
                    )}
                </>
            )}

            {type === "accountCredential" && (
                <>
                    {data.username && (
                        <CopyableField
                            label="Username"
                            value={data.username}
                            onCopy={onCopy}
                        />
                    )}
                    {data.password && (
                        <CopyableField
                            label="Password"
                            value={data.password}
                            onCopy={onCopy}
                            maskValue
                        />
                    )}
                    {data.notes && (
                        <CopyableField
                            label="Notes"
                            value={data.notes}
                            onCopy={onCopy}
                            multiline
                        />
                    )}
                </>
            )}

            {type === "emergencyContact" && (
                <>
                    {data.contactDetails && (
                        <CopyableField
                            label="Contact"
                            value={data.contactDetails}
                            onCopy={onCopy}
                        />
                    )}
                    {data.notes && (
                        <CopyableField
                            label="Message for contact"
                            value={data.notes}
                            onCopy={onCopy}
                            multiline
                        />
                    )}
                </>
            )}
        </Box>
    );
};
