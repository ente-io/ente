import { CustomErrors } from "../constants/errors";

export const isExecError = (err: any) => {
    return err.message.includes("Command failed:");
};

export const parseExecError = (err: any) => {
    const errMessage = err.message;
    if (errMessage.includes("Bad CPU type in executable")) {
        return CustomErrors.UNSUPPORTED_PLATFORM(
            process.platform,
            process.arch,
        );
    } else {
        return errMessage;
    }
};
