import { Button, ButtonProps, styled } from '@mui/material';
export const LivePhotoBtn = styled((props: ButtonProps) => (
    <Button color="secondary" {...props} />
))`
    position: absolute;
    bottom: 6vh;
    right: 6vh;
    outline: none;
    border: none;
    border-radius: 10%;
    z-index: 10;
    cursor: ${(props) => (props.disabled ? 'not-allowed' : 'pointer')};
    }
`;
