import { createProxyMiddleware } from 'http-proxy-middleware';

export const config = {
    api: {
      bodyParser: false,
    },
};

export default createProxyMiddleware({
    target: "http://api.staging.ente.io",
    changeOrigin: true,
    pathRewrite: { '^/api': '/' },
});
