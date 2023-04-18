let duration = 0;
let ratio = 0;

const ts2sec = (ts) => {
  const [h, m, s] = ts.split(':');
  return (parseFloat(h) * 60 * 60) + (parseFloat(m) * 60) + parseFloat(s);
};

module.exports = (message, progress) => {
  if (typeof message === 'string') {
    if (message.startsWith('  Duration')) {
      const ts = message.split(', ')[0].split(': ')[1];
      const d = ts2sec(ts);
      progress({ duration: d, ratio });
      if (duration === 0 || duration > d) {
        duration = d;
      }
    } else if (message.startsWith('frame') || message.startsWith('size')) {
      const ts = message.split('time=')[1].split(' ')[0];
      const t = ts2sec(ts);
      ratio = t / duration;
      progress({ ratio, time: t });
    } else if (message.startsWith('video:')) {
      progress({ ratio: 1 });
      duration = 0;
    }
  }
};
