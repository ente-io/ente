/// <reference types="chromecast-caf-receiver" />

import log from "@/next/log";

export type Cast = typeof cast;

/**
 * A holder for the "cast" global object exposed by the Chromecast SDK,
 * alongwith auxiliary state we need around it.
 */
class CastReceiver {
    /**
     * A reference to the `cast` global object that the Chromecast Web Receiver
     * SDK attaches to the window.
     *
     * https://developers.google.com/cast/docs/web_receiver/basic
     */
    cast: Cast | undefined;
    loader: Promise<Cast> | undefined;
}

const castReceiver = new CastReceiver();

/**
 * Load the Chromecast Web Receiver SDK and return a reference to the `cast`
 * global object that the SDK attaches to the window.
 *
 * Calling this function multiple times is fine, once the Chromecast SDK is
 * loaded it'll thereafter return the reference to the same object always.
 *
 * https://developers.google.com/cast/docs/web_receiver/basic
 */
export const castReceiverLoadingIfNeeded = async (): Promise<Cast> => {
    if (castReceiver.cast) return castReceiver.cast;
    if (castReceiver.loader) return await castReceiver.loader;

    castReceiver.loader = new Promise((resolve) => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        castReceiver.cast = cast;
        script.addEventListener("load", () => resolve(cast));
        document.body.appendChild(script);
    });

    return await castReceiver.loader;
};

/**
 * Listen for incoming messages on the given {@link cast} receiver, replying to
 * each of them with a pairing code obtained using the given {@link pairingCode}
 * callback. Phase 2 of the pairing protocol.
 *
 * See: [Note: Pairing protocol].
 */
export const advertiseCode = (
    cast: Cast,
    pairingCode: () => string | undefined,
) => {
    // Prepare the Chromecast "context".
    const context = cast.framework.CastReceiverContext.getInstance();
    const namespace = "urn:x-cast:pair-request";

    const options = new cast.framework.CastReceiverOptions();
    // We don't use the media features of the Cast SDK.
    options.skipPlayersLoad = true;
    // Do not stop the casting if the receiver is unreachable. A user should be
    // able to start a cast on their phone and then put it away, leaving the
    // cast running on their big screen.
    options.disableIdleTimeout = true;

    // The collection ID with which we paired. If we get another connection
    // request for a different collection ID, restart the app to allow them to
    // reconnect using a freshly generated pairing code.
    //
    // If the request does not have a collectionID, forego this check.
    let pairedCollectionID: string | undefined;

    type ListenerProps = {
        senderId: string;
        data: unknown;
    };

    // Reply with the code that we have if anyone asks over Chromecast.
    const incomingMessageListener = ({ senderId, data }: ListenerProps) => {
        const restart = (reason: string) => {
            log.error(`Restarting app: ${reason}`);
            // context.stop will close the tab but it'll get reopened again
            // immediately since the client app will reconnect in the scenarios
            // where we're calling this function.
            context.stop();
        };

        const collectionID =
            data &&
            typeof data == "object" &&
            typeof data["collectionID"] == "string"
                ? data["collectionID"]
                : undefined;

        if (pairedCollectionID && pairedCollectionID != collectionID) {
            restart(`incoming request for a new collection ${collectionID}`);
            return;
        }

        pairedCollectionID = collectionID;

        const code = pairingCode();
        if (!code) {
            // Our caller waits until it has a pairing code before it calls
            // `advertiseCode`, but there is still an edge case where we can
            // find ourselves without a pairing code:
            //
            // 1. The current pairing code expires. We start the process to get
            //    a new one.
            //
            // 2. But before that happens, someone connects.
            //
            // The window where this can happen is short, so if we do find
            // ourselves in this scenario,
            restart("we got a pairing request when refreshing pairing codes");
            return;
        }

        context.sendCustomMessage(namespace, senderId, { code });
    };

    context.addCustomMessageListener(
        namespace,
        // We need to cast, the `senderId` is present in the message we get but
        // not present in the TypeScript type.
        incomingMessageListener as unknown as SystemEventHandler,
    );

    // Close the (chromecast) tab if the sender disconnects.
    //
    // Chromecast does a "shutdown" of our cast app when we call `context.stop`.
    // This translates into it closing the tab where it is showing our app.
    context.addEventListener(
        cast.framework.system.EventType.SENDER_DISCONNECTED,
        () => context.stop(),
    );

    // Start listening for Chromecast connections.
    context.start(options);
};
