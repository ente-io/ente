import { EllipsizedTypography } from "@/base/components/Typography";
import { IconButtonWithBG } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    Button,
    Snackbar,
    Stack,
    SxProps,
    Theme,
    type ButtonProps,
} from "@mui/material";
import { NotificationAttributes } from "types/Notification";

interface Iprops {
    open: boolean;
    onClose: () => void;
    keepOpenOnClick?: boolean;
    attributes: NotificationAttributes;
    horizontal?: "left" | "right";
    vertical?: "top" | "bottom";
    sx?: SxProps<Theme>;
}

export default function Notification({
    open,
    onClose,
    horizontal,
    vertical,
    sx,
    attributes,
    keepOpenOnClick,
}: Iprops) {
    if (!attributes) {
        return <></>;
    }

    const handleClose: ButtonProps["onClick"] = (event) => {
        onClose();
        event.stopPropagation();
    };

    const handleClick = () => {
        attributes.onClick();
        if (!keepOpenOnClick) {
            onClose();
        }
    };
    return (
        <Snackbar
            open={open}
            anchorOrigin={{
                horizontal: horizontal ?? "right",
                vertical: vertical ?? "bottom",
            }}
            sx={{ width: "320px", backgroundColor: "#000", ...sx }}
        >
            <Button
                color={attributes.variant}
                onClick={handleClick}
                sx={{
                    textAlign: "left",
                    flex: "1",
                    padding: (theme) => theme.spacing(1.5, 2),
                    borderRadius: "8px",
                }}
            >
                <Stack
                    flex={"1"}
                    spacing={2}
                    direction="row"
                    alignItems={"center"}
                    width={"100%"}
                >
                    <Box sx={{ svg: { fontSize: "36px" } }}>
                        {attributes.startIcon ?? <InfoIcon />}
                    </Box>

                    <Stack
                        direction={"column"}
                        spacing={0.5}
                        flex={1}
                        textAlign="left"
                        // This is necessary to trigger the ellipsizing of the
                        // text in children.
                        overflow="hidden"
                    >
                        {attributes.subtext && (
                            <EllipsizedTypography variant="small">
                                {attributes.subtext}
                            </EllipsizedTypography>
                        )}
                        {attributes.message && (
                            <EllipsizedTypography fontWeight="bold">
                                {attributes.message}
                            </EllipsizedTypography>
                        )}
                        {attributes.title && (
                            <EllipsizedTypography fontWeight="bold">
                                {attributes.title}
                            </EllipsizedTypography>
                        )}
                        {attributes.caption && (
                            <EllipsizedTypography variant="small">
                                {attributes.caption}
                            </EllipsizedTypography>
                        )}
                    </Stack>

                    {attributes.endIcon ? (
                        <IconButtonWithBG
                            onClick={attributes.onClick}
                            sx={{ fontSize: "36px" }}
                        >
                            {attributes?.endIcon}
                        </IconButtonWithBG>
                    ) : (
                        <IconButtonWithBG onClick={handleClose}>
                            <CloseIcon />
                        </IconButtonWithBG>
                    )}
                </Stack>
            </Button>
        </Snackbar>
    );
}
