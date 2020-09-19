const WorkerPlugin = require('worker-plugin');

module.exports = {
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
};