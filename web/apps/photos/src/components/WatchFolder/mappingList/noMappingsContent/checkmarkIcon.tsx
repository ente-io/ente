import CheckIcon from "@mui/icons-material/Check";

export function CheckmarkIcon() {
    return (
        <CheckIcon
            fontSize="small"
            sx={{
                display: "inline",
                fontSize: "15px",

                color: (theme) => theme.palette.secondary.main,
            }}
        />
    );
}
