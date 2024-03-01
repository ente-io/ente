import { styled } from "@mui/material";
import { Button } from "react-bootstrap";
const Container = styled("div")`
    position: fixed;
    bottom: 7%;
    right: 2%;
    align-self: flex-end;
`;

interface Iprops {
    onClick: () => void;
}

export default function ReportAbuse(props: Iprops) {
    return (
        <Container>
            <Button onClick={props.onClick}>report abuse?</Button>
        </Container>
    );
}
