import CircularProgress, {
    type CircularProgressProps,
} from "@mui/material/CircularProgress";

export default function EnteSpinner(props: CircularProgressProps) {
    return <CircularProgress color="accent" size={32} {...props} />;
}
