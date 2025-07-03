/**
 * @file This code is conceputally related to `SecondFactorChoice.tsx`, but
 * needs to be in a separate file to allow fast refresh.
 */

import type { EmailOrSRPVerificationResponse } from "ente-accounts/services/user";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useCallback, useMemo, useRef } from "react";
import type { SecondFactorType } from "../SecondFactorChoice";

/**
 * A convenience hook for keeping track of the state and logic that is needed
 * after password verification to determine which second factor (if any) we
 * should be asking the user for.
 *
 * This is a rather ad-hoc abstraction meant to be used in a very specific way;
 * the only intent is to reduce code duplication between the two pages that need
 * this choice.
 */
export const useSecondFactorChoiceIfNeeded = () => {
    const resolveSecondFactorChoice = useRef<
        | ((value: SecondFactorType | PromiseLike<SecondFactorType>) => void)
        | undefined
    >(undefined);
    const {
        show: showSecondFactorChoice,
        props: secondFactorChoiceVisibilityProps,
    } = useModalVisibility();

    const onSelect = useCallback((factor: SecondFactorType) => {
        const resolve = resolveSecondFactorChoice.current!;
        resolveSecondFactorChoice.current = undefined;
        resolve(factor);
    }, []);

    const secondFactorChoiceProps = useMemo(
        () => ({ ...secondFactorChoiceVisibilityProps, onSelect }),
        [secondFactorChoiceVisibilityProps, onSelect],
    );

    const userVerificationResultAfterResolvingSecondFactorChoice = useCallback(
        async (response: EmailOrSRPVerificationResponse) => {
            const {
                twoFactorSessionID: _twoFactorSessionIDV1,
                twoFactorSessionIDV2: _twoFactorSessionIDV2,
                passkeySessionID: _passkeySessionID,
            } = response;

            // When the user has both TOTP and pk set as the second factor,
            // we'll get two session IDs. For backward compat, the TOTP session
            // ID will be in a V2 attribute during a transient migration period.
            //
            // Note the use of || instead of ?? since _twoFactorSessionIDV1 will
            // be an empty string, not undefined, if it is unset.
            const _twoFactorSessionID =
                _twoFactorSessionIDV1 || _twoFactorSessionIDV2;

            let passkeySessionID: string | undefined;
            let twoFactorSessionID: string | undefined;
            // If both factors are set, ask the user which one they want to use.
            if (_twoFactorSessionID && _passkeySessionID) {
                const choice = await new Promise<SecondFactorType>(
                    (resolve) => {
                        resolveSecondFactorChoice.current = resolve;
                        showSecondFactorChoice();
                    },
                );
                switch (choice) {
                    case "passkey":
                        passkeySessionID = _passkeySessionID;
                        break;
                    case "totp":
                        twoFactorSessionID = _twoFactorSessionID;
                        break;
                }
            } else {
                passkeySessionID = _passkeySessionID;
                twoFactorSessionID = _twoFactorSessionID;
            }

            return { ...response, passkeySessionID, twoFactorSessionID };
        },
        [showSecondFactorChoice],
    );

    return {
        secondFactorChoiceProps,
        userVerificationResultAfterResolvingSecondFactorChoice,
    };
};
