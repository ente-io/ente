import { styled } from '@mui/material';
export const LivePhotoBtn = styled('button')`
    position: absolute;
    bottom: 6vh;
    right: 6vh;
    height: 40px;
    width: 80px;
    background: #d7d7d7;
    outline: none;
    border: none;
    border-radius: 10%;
    z-index: 10;
    cursor: ${(props) => (props.disabled ? 'not-allowed' : 'pointer')};
    }
`;
