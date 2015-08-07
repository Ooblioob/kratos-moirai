module.exports = {
  name: 'moirai',
  worker: require('./worker'),
  validation: require('./validation'),
  authorization: require('./authorization'),
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
