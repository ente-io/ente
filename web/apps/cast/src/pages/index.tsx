import log from "@/next/log";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import LargeType from "components/LargeType";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { advertiseCode, getCastData, register } from "services/cast";
import { storeCastData } from "services/cast/castService";
import { useCastReceiver } from "../utils/useCastReceiver";

export default function PairingMode() {
    const [publicKeyB64, setPublicKeyB64] = useState<string | undefined>();
    const [privateKeyB64, setPrivateKeyB64] = useState<string | undefined>();
    const [pairingCode, setPairingCode] = useState<string | undefined>();

    // The returned cast object is a reference to a global instance and can be
    // used in a useEffect dependency list.
    const cast = useCastReceiver();

    const router = useRouter();

    const init = () => {
        register().then((r) => {
            setPublicKeyB64(r.publicKeyB64);
            setPrivateKeyB64(r.privateKeyB64);
            setPairingCode(r.pairingCode);
        });
    };

    useEffect(() => {
        init();
    }, []);

    useEffect(() => {
        if (cast) advertiseCode(cast, () => pairingCode);
    }, [cast]);

    const pollTick = async () => {
        const registration = { publicKeyB64, privateKeyB64, pairingCode };
        try {
            const data = await getCastData(registration);
            if (!data) {
                // No one has connected yet
                return;
            }

            log.info("Pairing complete");
            storeCastData(data);
            await router.push("/slideshow");
        } catch (e) {
            console.log("Failed to get cast data", e);
            // Start again from the beginning
            setPairingCode(undefined);
            init();
        }
    };

    useEffect(() => {
        if (!publicKeyB64 || !privateKeyB64 || !pairingCode) return;

        const interval = setInterval(pollTick, 2000);
        return () => clearInterval(interval);
    }, [publicKeyB64, privateKeyB64, pairingCode]);

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
                        Enter this code on <b>ente</b> to pair this TV
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
