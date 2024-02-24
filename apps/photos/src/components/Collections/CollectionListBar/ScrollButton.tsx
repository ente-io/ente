import { SCROLL_DIRECTION } from "@ente/shared/hooks/useComponentScroll";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import { css, styled } from "@mui/material";

const Wrapper = styled("button")<{ direction: SCROLL_DIRECTION }>`
    position: absolute;
    z-index: 2;
    top: 7px;
    height: 50px;
    width: 50px;
    border: none;
    padding: 0;
    margin: 0;

    border-radius: 50%;
    background-color: ${({ theme }) => theme.colors.backdrop.muted};
    color: ${({ theme }) => theme.colors.stroke.base};

    ${(props) =>
        props.direction === SCROLL_DIRECTION.LEFT
            ? css`
                  left: 0;
                  text-align: right;
                  transform: translate(-50%, 0%);
              `
            : css`
                  right: 0;
                  text-align: left;
                  transform: translate(50%, 0%);
              `}

    & > svg {
        ${(props) =>
            props.direction === SCROLL_DIRECTION.LEFT &&
            "transform:rotate(180deg);"}
        border-radius: 50%;
        height: 30px;
        width: 30px;
    }
`;

const ScrollButton = ({ scrollDirection, ...rest }) => (
    <Wrapper direction={scrollDirection} {...rest}>
        <NavigateNextIcon />
    </Wrapper>
);
export default ScrollButton;
