const chai = require('chai');
const constants = require('../tests/constants');

global.expect = chai.expect;
global.FFmpeg = require('../src');

Object.keys(constants).forEach((key) => {
  global[key] = constants[key];
});
