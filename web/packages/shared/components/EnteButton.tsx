import { ensure } from "@/utils/ensure";
import Done from "@mui/icons-material/Done";
import { Button, CircularProgress, type ButtonProps } from "@mui/material";

interface Iprops extends ButtonProps {
    loading?: boolean;
    success?: boolean;
}

export default function EnteButton({
    children,
    loading,
    success,
    disabled,
    sx,
    ...props
}: Iprops) {
    return (
        <Button
            disabled={disabled}
            sx={{
                ...sx,
                ...((loading || success) && {
                    "&.Mui-disabled": (theme) => ({
                        // TODO: Refactor to not need this ensure.
                        backgroundColor:
                            theme.palette[ensure(props.color)].main,
                        color: theme.palette[ensure(props.color)].contrastText,
                    }),
                }),
            }}
            {...props}
        >
            {loading ? (
                <CircularProgress size={20} sx={{ color: "inherit" }} />
            ) : success ? (
                <Done sx={{ fontSize: 20 }} />
            ) : (
                children
            )}
        </Button>
    );
}
