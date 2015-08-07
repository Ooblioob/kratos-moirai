_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
slug = require('slug')
querystring = require('querystring')

module.exports = (api, validation, couchUtils) ->
  users = api.users
  teams = api.teams
  auth = validation.auth
  conf = couchUtils.conf
  moiraiConf = conf.RESOURCES.MOIRAI
  couchClient = couchUtils.get_system_user()

  moirai = {}

  moirai.moiraiClient = Promise.RestClient({
    url: moiraiConf.URL,
    auth: moiraiConf.ADMIN_CREDENTIALS,
    json: true
  })

  emptyResolve = () ->
    Promise.resolve()

  moirai.setClusterKeys = (clusterId, keys) ->
    url = '/moirai/clusters/'+clusterId.replace('cluster_', '')+'/keys'
    return moirai.moiraiClient.put({url: url, json: keys, body_only: true})

  moirai.getTeamKeys = (team) ->
    adminNames = team.roles.admin?.members or []
    memberNames = team.roles.member?.members or []
    allMemberNames = _.unique(adminNames.concat(memberNames))
    users.getUsers(couchClient, {names: allMemberNames}, 'promise').then((userList) ->
      keyList = userList.map((user) ->
        return _.findWhere(user.data.publicKeys or [], {name: 'moirai'})
      )
      return Promise.resolve(_.compact(keyList).map((key) -> key.key))
    )

  moirai.setTeamKeys = (team) ->
    moirai.getTeamKeys(team).then((keys) ->
      clusters = team.rsrcs.moirai?.assets or []
      clusterIds = _.pluck(clusters, 'cluster_id')
      promisesList = clusterIds.map((clusterId) ->
        moirai.setClusterKeys(clusterId, keys)
      )
      Promise.all(promisesList).then(emptyResolve)
    )

  handleAddUser = (event, team) ->
    moirai.setTeamKeys(team)

  handleRemoveUser = (event, team) ->
    moirai.setTeamKeys(team)

  moirai.removeCluster = (cluster_id) ->
    url = '/moirai/clusters/' + cluster_id.replace('cluster_', '')
    return moirai.moiraiClient.del(url)

  handleRemoveCluster = (event, team) ->
    cluster_id = event.asset.cluster_id
    return moirai.removeCluster(cluster_id).then(emptyResolve)

  handleAddCluster = (event, team) ->
    cluster_id = event.asset.cluster_id
    # sleep so that moirai can record new ip addresses
    moirai.getTeamKeys(team).then((keys) ->
      moirai.setClusterKeys(cluster_id, keys).then(emptyResolve)
    )

  handleAddData = (event, user) ->
    # look at the event, see if one of the keys in the event is publicKeys
    if event.data.publicKeys?
      return teams.getAllTeamRolesForUser(user.name).then((teamList) ->
        teamPromises = teamList.map((teamHash) ->
          team = teamHash.team
          moirai.setTeamKeys(team)
        )
        return Promise.all(teamPromises).then(() ->
          Promise.resolve()
        )
      )
    else
      return Promise.resolve()


  getOrCreateAsset = (assetData, team, actor) ->
    url = '/moirai/clusters'
    clusters = team.rsrcs.moirai?.assets or []
    existingClusterWithName = _.findWhere(clusters, {name: assetData.name})
    if existingClusterWithName?
      return Promise.resolve()
    else
      moiraiData = {
        name: assetData.new,
        instances: [{
          tags: {
              Name: slug('moirai-' + team.name + '-' + assetData.new)
              Application: assetData.new
              BusinessOwner: team.name
              Creator: actor.data?.username or actor.name
          }
        }]
      }

      return moirai.moiraiClient.post({url: url, json: moiraiData, body_only: true}).then((newClusterData) ->
        Promise.resolve({
          cluster_id: newClusterData._id.slice(8),
          name: newClusterData.name,
        })
      )

  getTeamAssetDetails = (assets, team, actor) ->
    query = {clusterIds: _.pluck(assets, 'cluster_id')}
    url = '/moirai/clusters?' + querystring.stringify(query)
    moirai.moiraiClient.get({url: url, body_only: true})

  return {
    handlers:
      team:
        'u+': handleAddUser
        'u-': handleRemoveUser
        't+': null
        't-': null # if t- is implemented, this action should remove the cluster
        self:
          'a+': handleAddCluster
          'a-': handleRemoveCluster
        other:
          'a+': null
          'a-': null
      user:
        self:
          'r+': null
          'r-': null
        other:
          'r+': null
          'r-': null
        'u+': null
        'u-': null
        'd+': handleAddData
    getOrCreateAsset: getOrCreateAsset
    getTeamAssetDetails: getTeamAssetDetails
    testing: moirai
  }
