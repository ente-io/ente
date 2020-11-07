export const getEndpoint = () => {
    return process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "https://api.staging.ente.io";
}
