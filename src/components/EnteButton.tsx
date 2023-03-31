import Done from '@mui/icons-material/Done';
import { Button, ButtonProps, CircularProgress } from '@mui/material';
import { useEffect, useState } from 'react';

interface Iprops extends ButtonProps {
    loading: boolean;
}

export default function EnteButton({ children, loading, ...props }: Iprops) {
    const [success, setSuccess] = useState(false);

    useEffect(() => {
        if (loading === false) {
            setSuccess(true);
            setTimeout(() => setSuccess(false), 2000);
        }
    }, [loading]);

    return (
        <Button {...props} disabled={loading || success}>
            {loading ? (
                <CircularProgress size={20} />
            ) : success ? (
                <Done sx={{ fontSize: 20 }} />
            ) : (
                children
            )}
        </Button>
    );
}
