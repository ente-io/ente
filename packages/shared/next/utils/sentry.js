const {
    getAppEnv,
    ENV_DEVELOPMENT,
    isDisableSentryFlagSet,
} = require('../env.js');
const cp = require('child_process');

module.exports.getIsSentryEnabled = () => {
    const isAppENVDevelopment = getAppEnv() === ENV_DEVELOPMENT;
    const isSentryDisabled = isDisableSentryFlagSet();
    return !isAppENVDevelopment || !isSentryDisabled;
};

module.exports.getGitSha = () =>
    cp.execSync('git rev-parse --short HEAD', {
        cwd: __dirname,
        encoding: 'utf8',
    });
