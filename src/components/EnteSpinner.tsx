import React from 'react';
import CircularProgress from '@mui/material/CircularProgress';

export default function EnteSpinner(props) {
    return <CircularProgress color="accent" size={32} {...props} />;
}
