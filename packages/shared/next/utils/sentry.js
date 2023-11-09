const {
    getAppEnv,
    ENV_DEVELOPMENT,
    isEnableSentryFlagSet,
} = require('../env.js');
const cp = require('child_process');

module.exports.getIsSentryEnabled = () => {
    const isAppENVDevelopment = getAppEnv() === ENV_DEVELOPMENT;
    const isSentryEnabled = isEnableSentryFlagSet();
    return !isAppENVDevelopment || isSentryEnabled;
};

module.exports.getGitSha = () =>
    cp.execSync('git rev-parse --short HEAD', {
        cwd: __dirname,
        encoding: 'utf8',
    });
