module.exports = {
  plugins: {
    autoprefixer: {
      stats: {},
      overrideBrowserslist: [
        '> 0.5%',
        'last 2 versions',
        'Firefox ESR',
        'not dead'
      ]
    }
  }
};
