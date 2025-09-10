import { memo } from "react";
import Image from "next/image";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { JourneyPoint } from "./types";

interface TripCoverProps {
    journeyData: JourneyPoint[];
    photoClusters: JourneyPoint[][];
    albumTitle?: string;
    coverImageUrl?: string | null;
}

export const TripCover = memo<TripCoverProps>(({
    journeyData,
    photoClusters,
    albumTitle,
    coverImageUrl,
}) => {
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() -
            new Date(b.timestamp).getTime(),
    );
    const firstData = sortedData[0];
    const lastData = sortedData[sortedData.length - 1];
    if (!firstData || !lastData) {
        return null;
    }
    const firstDate = new Date(firstData.timestamp);
    const lastDate = new Date(lastData.timestamp);
    const diffTime = Math.abs(lastDate.getTime() - firstDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    const monthYear = firstDate.toLocaleDateString("en-US", {
        month: "long",
        year: "numeric",
    });

    return (
        <div style={{ marginBottom: "48px" }}>
            <div
                style={{
                    aspectRatio: "16/8",
                    position: "relative",
                    marginBottom: "12px",
                    borderRadius: "24px",
                    overflow: "hidden",
                }}
            >
                <Image
                    src={coverImageUrl || journeyData[0]?.image || ""}
                    alt="Trip Cover"
                    fill
                    style={{ objectFit: "cover" }}
                    sizes="(max-width: 768px) 90vw, (max-width: 1200px) 45vw, 600px"
                />
                <div
                    style={{
                        position: "absolute",
                        inset: 0,
                        background:
                            "linear-gradient(to bottom, rgba(0,0,0,0.4), transparent 30%, transparent 70%, rgba(0,0,0,0.7))",
                    }}
                ></div>

                {/* Ente logo */}
                <div
                    style={{
                        position: "absolute",
                        top: "20px",
                        left: "20px",
                        color: "#22c55e",
                    }}
                >
                    <EnteLogo height={24} />
                </div>

                <div
                    style={{
                        position: "absolute",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        padding: "24px",
                        color: "white",
                    }}
                >
                    <h1
                        style={{
                            fontSize: "30px",
                            fontWeight: "bold",
                            marginBottom: "2px",
                        }}
                    >
                        {albumTitle || "Trip"}
                    </h1>
                    <p
                        style={{
                            color: "rgba(255, 255, 255, 0.8)",
                            fontSize: "16px",
                            fontWeight: "600",
                            margin: "0",
                        }}
                    >
                        {monthYear} • {diffDays} days •{" "}
                        {photoClusters.length} locations
                    </p>
                </div>
            </div>
        </div>
    );
});