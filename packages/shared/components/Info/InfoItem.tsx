import { FlexWrapper } from "@ente/shared/components/Container";
import Edit from "@mui/icons-material/Edit";
import { Box, IconButton, Typography } from "@mui/material";
import { SmallLoadingSpinner } from "../styledComponents/SmallLoadingSpinner";

interface Iprops {
    icon: JSX.Element;
    title?: string;
    caption?: string | JSX.Element;
    openEditor?: any;
    loading?: boolean;
    hideEditOption?: any;
    customEndButton?: any;
    children?: any;
}

export default function InfoItem({
    icon,
    title,
    caption,
    openEditor,
    loading,
    hideEditOption,
    customEndButton,
    children,
}: Iprops): JSX.Element {
    return (
        <FlexWrapper justifyContent="space-between">
            <Box display={"flex"} alignItems="flex-start" gap={0.5} pr={1}>
                <IconButton
                    color="secondary"
                    sx={{ "&&": { cursor: "default", m: 0.5 } }}
                    disableRipple
                >
                    {icon}
                </IconButton>
                <Box py={0.5}>
                    {children ? (
                        children
                    ) : (
                        <>
                            <Typography sx={{ wordBreak: "break-all" }}>
                                {title}
                            </Typography>
                            <Typography variant="small" color="text.muted">
                                {caption}
                            </Typography>
                        </>
                    )}
                </Box>
            </Box>
            {customEndButton
                ? customEndButton
                : !hideEditOption && (
                      <IconButton onClick={openEditor} color="secondary">
                          {!loading ? <Edit /> : <SmallLoadingSpinner />}
                      </IconButton>
                  )}
        </FlexWrapper>
    );
}
