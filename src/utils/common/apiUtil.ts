export const getEndpoint = () => {
    const endPoint = process.env.NEXT_PUBLIC_ENV == "local" ? "http://localhost:8080" : process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "https://api.ente.io";
    console.log(endPoint);
    return endPoint;
}
