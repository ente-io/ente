import { createProxyMiddleware } from 'http-proxy-middleware';

export const config = {
  api: {
    bodyParser: false,
  },
};

const API_ENDPOINT = process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "http://192.168.0.100";

export default createProxyMiddleware({
  target: API_ENDPOINT,
  changeOrigin: true,
  pathRewrite: { '^/api': '/' },
});
