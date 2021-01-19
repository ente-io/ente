export const getEndpoint = () => {
    return process.env.ENV == "local" ? "http://localhost:8080" : process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "https://api.ente.io";
}
