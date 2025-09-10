import { memo } from "react";
import { JourneyPoint } from "./types";

interface TripStartedSectionProps {
    journeyData: JourneyPoint[];
}

export const TripStartedSection = memo<TripStartedSectionProps>(({ journeyData }) => {
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() -
            new Date(b.timestamp).getTime(),
    );
    const firstData = sortedData[0];
    if (!firstData) {
        return null;
    }
    const firstDate = new Date(firstData.timestamp);

    return (
        <div
            style={{
                position: "relative",
                marginTop: "32px",
                marginBottom: "100px",
                textAlign: "center",
                zIndex: 1,
            }}
        >
            <div
                style={{
                    fontSize: "20px",
                    fontWeight: "600",
                    color: "#111827",
                    marginBottom: "2px",
                    lineHeight: "1.2",
                    backgroundColor: "white",
                    padding: "4px 8px",
                    borderRadius: "4px",
                    display: "inline-block",
                }}
            >
                Trip started
            </div>
            <br />
            <div
                style={{
                    fontSize: "14px",
                    color: "#6b7280",
                    backgroundColor: "white",
                    padding: "2px 6px",
                    borderRadius: "4px",
                    display: "inline-block",
                    marginTop: "0px",
                }}
            >
                {firstDate.toLocaleDateString("en-US", {
                    month: "long",
                    day: "2-digit",
                })}
            </div>

            {/* Starting dot after some space */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    top: "80px",
                    transform: "translate(-50%, 0)",
                    borderRadius: "50%",
                    border: "2px solid white",
                    zIndex: 20,
                    width: "12px",
                    height: "12px",
                    backgroundColor: "#d1d5db",
                }}
            ></div>
        </div>
    );
});