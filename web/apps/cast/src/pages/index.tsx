import log from "@/next/log";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { styled } from "@mui/material";
import { PairingCode } from "components/PairingCode";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { readCastData, storeCastData } from "services/cast-data";
import { getCastData, register } from "services/pair";
import { advertiseOnChromecast } from "../services/chromecast";

export default function Index() {
    const [publicKeyB64, setPublicKeyB64] = useState<string | undefined>();
    const [privateKeyB64, setPrivateKeyB64] = useState<string | undefined>();
    const [pairingCode, setPairingCode] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        if (!pairingCode) {
            register().then((r) => {
                setPublicKeyB64(r.publicKeyB64);
                setPrivateKeyB64(r.privateKeyB64);
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
        if (!publicKeyB64 || !privateKeyB64 || !pairingCode) return;

        const interval = setInterval(pollTick, 2000);
        return () => clearInterval(interval);
    }, [publicKeyB64, privateKeyB64, pairingCode]);

    const pollTick = async () => {
        if (!publicKeyB64 || !privateKeyB64 || !pairingCode) return;

        const registration = { publicKeyB64, privateKeyB64, pairingCode };
        try {
            const data = await getCastData(registration);
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

    return (
        <Container>
            <img width={150} src="/images/ente.svg" />
            <h1>
                Enter this code on <b>Ente Photos</b> to pair this screen
            </h1>
            {pairingCode ? <PairingCode code={pairingCode} /> : <Spinner />}
            <p>
                Visit{" "}
                <a href="https://ente.io/cast" target="_blank">
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

    h1 {
        font-weight: normal;
    }

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
        <EnteSpinner />
    </Spinner_>
);

const Spinner_ = styled("div")`
    /* Roughly same height as the pairing code section to roduce layout shift */
    margin-block: 1.7rem;
`;
