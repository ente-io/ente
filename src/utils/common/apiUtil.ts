export const getEndpoint = () => {
    const endPoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? "https://api.ente.io";
    console.log(endPoint);
    return endPoint;
}
