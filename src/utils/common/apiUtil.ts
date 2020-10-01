export const getEndpoint = () => {
    const dev = process.env.NODE_ENV === 'development';
    const apiEndpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "http://192.168.0.100";
    const endpoint = !dev ? apiEndpoint : '/api';
    return endpoint;
}