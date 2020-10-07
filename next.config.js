const WorkerPlugin = require('worker-plugin');
const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
    target: 'serverless',
    webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
        if (!isServer) {
          config.plugins.push(
            new WorkerPlugin({
              // use "self" as the global object when receiving hot updates.
              globalObject: 'self',
            })
          )
        }
        return config
    },
});
