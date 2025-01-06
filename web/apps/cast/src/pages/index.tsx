import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import log from "@/base/log";
import { styled, Typography } from "@mui/material";
import { PairingCode } from "components/PairingCode";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { readCastData, storeCastData } from "services/cast-data";
import { getCastPayload, register } from "services/pair";
import { advertiseOnChromecast } from "../services/chromecast-receiver";

export default function Index() {
    const [publicKey, setPublicKey] = useState<string | undefined>();
    const [privateKey, setPrivateKey] = useState<string | undefined>();
    const [pairingCode, setPairingCode] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        if (!pairingCode) {
            void register().then((r) => {
                setPublicKey(r.publicKey);
                setPrivateKey(r.privateKey);
                setPairingCode(r.pairingCode);
            });
        } else {
            advertiseOnChromecast(
                () => pairingCode,
                () => readCastData()?.collectionID,
            );
        }
    }, [pairingCode]);

    useEffect(() => {
        if (!publicKey || !privateKey || !pairingCode) return;

        const pollTick = async () => {
            try {
                const data = await getCastPayload({
                    publicKey,
                    privateKey,
                    pairingCode,
                });
                if (!data) {
                    // No one has connected yet.
                    return;
                }

                storeCastData(data);
                await router.push("/slideshow");
            } catch (e) {
                // The pairing code becomes invalid after an hour, which will cause
                // `getCastData` to fail. There might be other reasons this might
                // fail too, but in all such cases, it is a reasonable idea to start
                // again from the beginning.
                log.warn("Failed to get cast data", e);
                setPairingCode(undefined);
            }
        };

        const interval = setInterval(pollTick, 2000);
        return () => clearInterval(interval);
    }, [publicKey, privateKey, pairingCode, router]);

    return (
        <Container>
            <img width={150} src="/images/ente.svg" />
            <Typography
                variant="h2"
                sx={{ fontWeight: "500", marginBlock: "2rem" }}
            >
                Enter this code on <b>Ente Photos</b> to pair this screen
            </Typography>
            {pairingCode ? <PairingCode code={pairingCode} /> : <Spinner />}
            <p>
                Visit{" "}
                <a href="https://ente.io/cast" target="_blank" rel="noopener">
                    ente.io/cast
                </a>{" "}
                for help
            </p>
        </Container>
    );
}

const Container = styled("div")`
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;

    p {
        font-size: 1.2rem;
    }
    a {
        text-decoration: none;
        color: #87cefa;
        font-weight: bold;
    }
`;

const Spinner: React.FC = () => (
    <Spinner_>
        <ActivityIndicator />
    </Spinner_>
);

const Spinner_ = styled("div")`
    /* Roughly same height as the pairing code section to roduce layout shift */
    margin-block: 1.7rem;
`;
