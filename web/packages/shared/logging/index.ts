import log from "@/next/log";

export function addLogLine(
    msg: string | number | boolean,
    ...optionalParams: (string | number | boolean)[]
) {
    const completeLog = [msg, ...optionalParams].join(" ");
    log.info(completeLog);
}
