import { Overlay } from "@ente/shared/components/Container";
import {
    CircularProgress,
    CircularProgressProps,
    Typography,
} from "@mui/material";

function CircularProgressWithLabel(
    props: CircularProgressProps & { value: number },
) {
    return (
        <>
            <CircularProgress variant="determinate" {...props} color="accent" />
            <Overlay
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    height: "40px",
                }}
            >
                <Typography
                    variant="mini"
                    component="div"
                    color="text.secondary"
                >{`${Math.round(props.value)}%`}</Typography>
            </Overlay>
        </>
    );
}

export default CircularProgressWithLabel;
