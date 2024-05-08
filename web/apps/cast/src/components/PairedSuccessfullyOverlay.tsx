import { styled } from "@mui/material";
import { FilledCircleCheck } from "./FilledCircleCheck";

export const PairedSuccessfullyOverlay: React.FC = () => {
    return (
        <div
            style={{
                position: "fixed",
                top: 0,
                right: 0,
                height: "100%",
                width: "100%",
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
                zIndex: 100,
                backgroundColor: "black",
            }}
        >
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
        </div>
    );
};

export const PairingSuccessful_ = styled("div")`
    position: fixed;
    top: 0;
    right: 0;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 100;
    background-color: black;
`;
