import styled from 'styled-components';

const Wrapper = styled.div<{ open: boolean }>`
    background-color: #111;
    color: #fff;
    min-height: 64px;
    align-items: center;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.7);
    margin-bottom: 10px;
    position: fixed;
    top: 0;
    width: 100%;
    z-index: 2000;
    display: ${(props) => (props.open ? 'block' : 'none')};
`;

export default function SearchBar(props) {
    return <Wrapper {...props}></Wrapper>;
}
