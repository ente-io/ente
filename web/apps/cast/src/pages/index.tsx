import EnteSpinner from "@ente/shared/components/EnteSpinner";
import LargeType from "components/LargeType";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { pair, register, type Registration } from "services/cast";
import { storeCastData } from "services/cast/castService";
import { useCastReceiver } from "../utils/useCastReceiver";

export default function PairingMode() {
    const [registration, setRegistration] = useState<
        Registration | undefined
    >();
    const [deviceCode, setDeviceCode] = useState("");

    const cast = useCastReceiver();

    // useEffect(() => {
    //     init();
    // }, []);

    // const init = async () => {
    //     try {
    //         const keypair = await generateKeyPair();
    //         setPublicKeyB64(await toB64(keypair.publicKey));
    //         setPrivateKeyB64(await toB64(keypair.privateKey));
    //     } catch (e) {
    //         log.error("failed to generate keypair", e);
    //         throw e;
    //     }
    // };

    // useEffect(() => {
    //     if (!cast) {
    //         return;
    //     }
    //     if (isCastReady) {
    //         return;
    //     }
    //     const context = cast.framework.CastReceiverContext.getInstance();

    //     try {
    //         const options = new cast.framework.CastReceiverOptions();
    //         options.maxInactivity = 3600;
    //         options.customNamespaces = Object.assign({});
    //         options.customNamespaces["urn:x-cast:pair-request"] =
    //             cast.framework.system.MessageType.JSON;

    //         options.disableIdleTimeout = true;
    //         context.set;

    //         context.addCustomMessageListener(
    //             "urn:x-cast:pair-request",
    //             messageReceiveHandler,
    //         );

    //         // listen to close request and stop the context
    //         context.addEventListener(
    //             cast.framework.system.EventType.SENDER_DISCONNECTED,
    //             // eslint-disable-next-line @typescript-eslint/no-unused-vars
    //             (_) => {
    //                 context.stop();
    //             },
    //         );
    //         context.start(options);
    //         setIsCastReady(true);
    //     } catch (e) {
    //         log.error("failed to create cast context", e);
    //     }

    //     return () => {
    //         // context.stop();
    //     };
    // }, [cast]);

    // const messageReceiveHandler = (message: {
    //     type: string;
    //     senderId: string;
    //     data: any;
    // }) => {
    //     try {
    //         cast.framework.CastReceiverContext.getInstance().sendCustomMessage(
    //             "urn:x-cast:pair-request",
    //             message.senderId,
    //             {
    //                 code: deviceCode,
    //             },
    //         );
    //     } catch (e) {
    //         log.error("failed to send message", e);
    //     }
    // };

    // const generateKeyPair = async () => {
    //     await _sodium.ready;
    //     const keypair = _sodium.crypto_box_keypair();
    //     return keypair;
    // };

    // const pollForCastData = async () => {
    //     if (codePending) {
    //         return;
    //     }
    //     // see if we were acknowledged on the client.
    //     // the client will send us the encrypted payload using our public key that we advertised.
    //     // then, we can decrypt this and store all the necessary info locally so we can play the collection slideshow.
    //     let devicePayload = "";
    //     try {
    //         const encDastData = await castGateway.getCastData(`${deviceCode}`);
    //         if (!encDastData) return;
    //         devicePayload = encDastData;
    //     } catch (e) {
    //         setCodePending(true);
    //         init();
    //         return;
    //     }

    //     const decryptedPayload = await boxSealOpen(
    //         devicePayload,
    //         publicKeyB64,
    //         privateKeyB64,
    //     );

    //     const decryptedPayloadObj = JSON.parse(atob(decryptedPayload));

    //     return decryptedPayloadObj;
    // };

    // const advertisePublicKey = async (publicKeyB64: string) => {
    //     // hey client, we exist!
    //     try {
    //         const codeValue = await castGateway.registerDevice(publicKeyB64);
    //         setDeviceCode(codeValue);
    //         setCodePending(false);
    //     } catch (e) {
    //         // schedule re-try after 5 seconds
    //         setTimeout(() => {
    //             init();
    //         }, 5000);
    //         return;
    //     }
    // };

    const router = useRouter();

    useEffect(() => {
        register().then((r) => setRegistration(r));
    }, []);

    useEffect(() => {
        if (!cast || !registration) return;

        pair(cast, registration).then((data) => {
            storeCastData(data);
            router.push("/slideshow");
        });
    }, [cast, registration]);

    // useEffect(() => {
    //     if (!publicKeyB64) return;
    //     advertisePublicKey(publicKeyB64);
    // }, [publicKeyB64]);

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
                        {deviceCode ? (
                            <LargeType chars={deviceCode.split("")} />
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
