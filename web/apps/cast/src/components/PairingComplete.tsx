import { styled } from "@mui/material";
import { FilledCircleCheck } from "./FilledCircleCheck";

export const PairingComplete: React.FC = () => {
    return (
        <PairingComplete_>
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    flexDirection: "column",
                    textAlign: "center",
                }}
            >
                <FilledCircleCheck />
                <h2
                    style={{
                        marginBottom: 0,
                    }}
                >
                    Pairing Complete
                </h2>
                <p
                    style={{
                        lineHeight: "1.5rem",
                    }}
                >
                    We're preparing your album.
                    <br /> This should only take a few seconds.
                </p>
            </div>
        </PairingComplete_>
    );
};

const PairingComplete_ = styled("div")`
    display: flex;
    min-height: 100svh;
    justify-content: center;
    align-items: center;
`;
