import log from "@/next/log";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { LargeType } from "components/LargeType";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { storeCastData } from "services/cast";
import { advertiseCode, getCastData, register } from "services/pair";
import { castReceiverLoadingIfNeeded } from "../utils/cast-receiver";

export default function Index() {
    const [publicKeyB64, setPublicKeyB64] = useState<string | undefined>();
    const [privateKeyB64, setPrivateKeyB64] = useState<string | undefined>();
    const [pairingCode, setPairingCode] = useState<string | undefined>();
    // TODO: This needs to change, since there is an interim period when the
    // code becomes invalid.
    const [haveInitializedCast, setHaveInitializedCast] = useState(false);

    const router = useRouter();

    useEffect(() => {
        init();
    }, []);

    const init = () => {
        register().then((r) => {
            setPublicKeyB64(r.publicKeyB64);
            setPrivateKeyB64(r.privateKeyB64);
            setPairingCode(r.pairingCode);
        });
    };

    useEffect(() => {
        if (pairingCode && !haveInitializedCast) {
            castReceiverLoadingIfNeeded().then((cast) => {
                setHaveInitializedCast(true);
                advertiseCode(cast, () => pairingCode);
            });
        }
    }, [pairingCode]);

    useEffect(() => {
        if (!publicKeyB64 || !privateKeyB64 || !pairingCode) return;

        const interval = setInterval(pollTick, 2000);
        return () => clearInterval(interval);
    }, [publicKeyB64, privateKeyB64, pairingCode]);

    const pollTick = async () => {
        const registration = { publicKeyB64, privateKeyB64, pairingCode };
        try {
            const data = await getCastData(registration);
            if (!data) {
                // No one has connected yet.
                return;
            }

            log.info("Pairing complete");
            storeCastData(data);
            await router.push("/slideshow");
        } catch (e) {
            // Code has become invalid
            log.error("Failed to get cast data", e);
            // Start again from the beginning.
            setPairingCode(undefined);
            init();
        }
    };

    return (
        <>
            <div
                style={{
                    height: "100%",
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center",
                }}
            >
                <div
                    style={{
                        textAlign: "center",
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                    }}
                >
                    <img width={150} src="/images/ente.svg" />
                    <h1
                        style={{
                            fontWeight: "normal",
                        }}
                    >
                        Enter this code on <b>Ente Photos</b> to pair this
                        screen
                    </h1>
                    <div
                        style={{
                            borderRadius: "10px",
                            overflow: "hidden",
                        }}
                    >
                        {pairingCode ? (
                            <LargeType chars={pairingCode.split("")} />
                        ) : (
                            <EnteSpinner />
                        )}
                    </div>
                    <p
                        style={{
                            fontSize: "1.2rem",
                        }}
                    >
                        Visit{" "}
                        <a
                            style={{
                                textDecoration: "none",
                                color: "#87CEFA",
                                fontWeight: "bold",
                            }}
                            href="https://ente.io/cast"
                            target="_blank"
                        >
                            ente.io/cast
                        </a>{" "}
                        for help
                    </p>
                </div>
            </div>
        </>
    );
}
