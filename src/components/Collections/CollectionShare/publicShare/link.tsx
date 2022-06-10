import { Box } from '@mui/material';
import CodeBlock from 'components/CodeBlock';
import React from 'react';

export default function PublicShareLink({ publicShareUrl }) {
    return (
        <Box mt={2} mb={3}>
            <CodeBlock wordBreak={'break-all'} code={publicShareUrl} />
        </Box>
    );
}
