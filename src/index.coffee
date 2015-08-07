module.exports = {
  name: 'moirai',
  worker: require('./worker'),
  validation: require('./validation'),
  authorization: require('./authorization'),
  proxy: require('./proxy'),
  roles:
    team: [
      'admin',
      'member',
    ],
    team_admin: [
      'admin',
    ],
    resource: []
}
