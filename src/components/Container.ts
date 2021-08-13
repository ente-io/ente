import styled from 'styled-components';

const Container = styled.div`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    overflow: auto;
    padding: 10px;
`;

export default Container;

export const DisclaimerContainer = styled.div`
    margin: 16px 0;
    color: rgb(158, 150, 137);
    font-size: 14px;
`;

export const IconButton = styled.button`
    background: none;
    border: none;
    border-radius: 50%;
    width: 40px;
    height: 40px;
    padding: 5px;
    color: inherit;
    margin: 0 10px;
    display: inline-flex;
    align-items: center;
    justify-content: center;

    &:focus,
    &:hover {
        background-color: rgba(255, 255, 255, 0.2);
    }
`;

export const Row = styled.div`
    display: flex;
    align-items: center;
    margin-bottom: 20px;
    flex: 1;
`;

export const Label = styled.div<{ width?: string }>`
    width: ${(props) => props.width ?? '70%'};
`;
export const Value = styled.div<{ width?: string }>`
    display: flex;
    justify-content: flex-start;
    align-items: center;
    width: ${(props) => props.width ?? '30%'};
    text-align: center;
    color: #ddd;
`;
