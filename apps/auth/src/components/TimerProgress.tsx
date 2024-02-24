import { useEffect, useState } from "react";

const TimerProgress = ({ period }) => {
    const [progress, setProgress] = useState(0);
    const [ticker, setTicker] = useState(null);
    const microSecondsInPeriod = period * 1000000;

    const startTicker = () => {
        const ticker = setInterval(() => {
            updateTimeRemaining();
        }, 10);
        setTicker(ticker);
    };

    const updateTimeRemaining = () => {
        const timeRemaining =
            microSecondsInPeriod -
            ((new Date().getTime() * 1000) % microSecondsInPeriod);
        setProgress(timeRemaining / microSecondsInPeriod);
    };

    useEffect(() => {
        startTicker();
        return () => clearInterval(ticker);
    }, []);

    const color = progress > 0.4 ? "green" : "orange";

    return (
        <div
            style={{
                borderTopLeftRadius: "3px",
                width: `${progress * 100}%`,
                height: "3px",
                backgroundColor: color,
            }}
        />
    );
};

export default TimerProgress;
