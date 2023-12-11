import { styled } from '@mui/material/styles';
import LinkButton from '@ente/shared/components/LinkButton';

// allow passing width to the styled component
export const FolderPathContainer = styled(LinkButton)(
    ({ width }) => `
    width: ${width}px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    /* Beginning of string */
    direction: rtl;
    text-align: left;
`
);
