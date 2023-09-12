import { Button, ButtonProps, styled } from '@mui/material';
export const ConvertBtn = styled((props: ButtonProps) => (
    <Button color="secondary" {...props} />
))`
    position: absolute;
    bottom: 10vh;
    left: 2vh;
    outline: none;
    border: none;
    border-radius: 10%;
    z-index: 10;
    cursor: ${(props) => (props.disabled ? 'not-allowed' : 'pointer')};
    }
`;
