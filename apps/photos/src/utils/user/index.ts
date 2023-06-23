import isElectron from 'is-electron';
import { UserDetails } from 'types/user';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import ElectronService from 'services/electron/common';
import { SRP, SrpClient } from 'fast-srp-hap';
import { Buffer } from 'buffer';

export function makeID(length) {
    let result = '';
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}

export async function getSentryUserID() {
    if (isElectron()) {
        return await ElectronService.getSentryUserID();
    } else {
        let anonymizeUserID = getData(LS_KEYS.AnonymizedUserID)?.id;
        if (!anonymizeUserID) {
            anonymizeUserID = makeID(6);
            setData(LS_KEYS.AnonymizedUserID, { id: anonymizeUserID });
        }
        return anonymizeUserID;
    }
}

export function getLocalUserDetails(): UserDetails {
    return getData(LS_KEYS.USER_DETAILS)?.value;
}

export const isInternalUser = () => {
    const userEmail = getData(LS_KEYS.USER)?.email;
    if (!userEmail) return false;

    return (
        userEmail.endsWith('@ente.io') || userEmail === 'kr.anand619@gmail.com'
    );
};

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString('base64');
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, 'base64');
};

const SRP_PARAMS = SRP.params[4096];
export const testSRP = async () => {
    const srpSalt = 'asdasdad';
    const email = 'a@ente.io';
    const password = '12345678';

    const srpVerifier = SRP.computeVerifier(
        SRP_PARAMS,
        Buffer.from(srpSalt),
        Buffer.from(email),
        Buffer.from(password)
    );
    console.log('srpVerifier', convertBufferToBase64(srpVerifier));

    const srpClient = await generateSRPClient(srpSalt, email, password);

    const srpA = srpClient.computeA();

    console.log('srpA', convertBufferToBase64(srpA));

    const srpB =
        'LsUM9CMB7WWpImX+gTlxuqdcuGbBYYebbuXn0D5NlL/Toh6q3/TN7fajPnyuGppzg8P55TbGRl6rD19NM1qlMnQVfHGYZDuBOefoe4kfZ5JtueeoCDrDdmfzI2zRaPygsZ3tNRjVj8KGbhYYt5sXzdKB1NvAvpdOQ7aPyZwzd3LL8SwMUn6930OQYSRxdvNcIuibYG89VKx6vJWNU3J20cBsNEZ6FHWwSZw48j1ACmgXHiHxjJ8GADT/k1SUWEcf8d5u5vNRnnQ8ThvLvasO0IA2YQ+5zAYYB/ErPwo+MNQvEtbfJZu1Xi1ILPutzKPwYI7TRzvxpW9XSrTw0K1G0T0o+fibwusf7GJ5PS8ech5dOtBT0i/cQ2HUYTVwWyxO/j9PevyNFkW236amRgcOxO8/K60+6PcMlLJRjrzNxZjdkhexG/YrDYCPpC6g38WatDtNWhynL0AweIg0yAIbw2tZ94cfrebLBJ4sRyH5OyPRnMlaJc8arW+/98347y9bdAZJtL7yjJbUBUAqmfn6HJeqp1Su+FoYr2hp8dvJ/tjAbjXRLtJt5VTzRAC6BQ6cjC9iA8TjXKP8HCaLoXuylV3IxbOkeA1qZAJ8K1zflFUnJNbpHPUaDMzui5zxDQOlP+1le+K/mTqxSWCibkHeICQZcnV6NDCeRYbRlP1DVds=';
    srpClient.setB(convertBase64ToBuffer(srpB));

    const srpK = srpClient.computeK();

    console.log('srpK', convertBufferToBase64(srpK));

    const srpM1 = srpClient.computeM1();

    console.log('srpM1', convertBufferToBase64(srpM1));
};

const generateSRPClient = async (
    srpSalt: string,
    email: string,
    password: string
) => {
    const secret1 = 'HU36bI7kqNNGQFDZQYuc/4W39OlOfTjQr3GRJ59czEA=';

    const srpClient = new SrpClient(
        SRP_PARAMS,
        Buffer.from(srpSalt),
        Buffer.from(email),
        Buffer.from(password),
        Buffer.from(secret1)
    );

    return srpClient;
};
