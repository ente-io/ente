import CircularProgress, {
    CircularProgressProps,
} from '@mui/material/CircularProgress';

export default function EnteSpinner(props: CircularProgressProps) {
    return <CircularProgress color="error" size={32} {...props} />;
}
