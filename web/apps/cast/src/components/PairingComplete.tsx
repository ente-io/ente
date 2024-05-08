import { styled } from "@mui/material";
import { FilledCircleCheck } from "./FilledCircleCheck";

export const PairingComplete: React.FC = () => {
    return (
        <PairingComplete_>
            <Items>
                <FilledCircleCheck />
                <h2>Pairing Complete</h2>
                <p>
                    We're preparing your album.
                    <br /> This should only take a few seconds.
                </p>
            </Items>
        </PairingComplete_>
    );
};

const PairingComplete_ = styled("div")`
    display: flex;
    min-height: 100svh;
    justify-content: center;
    align-items: center;

    line-height: 1.5rem;

    h2 {
        margin-block-end: 0;
    }
`;

const Items = styled("div")`
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
`;
