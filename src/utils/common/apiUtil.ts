export const getEndpoint = () => {
    const dev = process.env.NODE_ENV === 'development';
    const apiEndpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "https://api.staging.ente.io";
    const endpoint = !dev ? apiEndpoint : '/api';
    return endpoint;
}