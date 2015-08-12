moirai = require('../lib/worker')
Promise = require('promise')
_ = require('underscore')

beforeEvery = () ->
  this.api = {
    users: {
      getUsers: jasmine.createSpy('getUsers').andReturn(Promise.resolve([
        {
          _id: 'org.couchdb.user:member1',
          data: {
            publicKeys: [{name: 'moirai', key: 'keyvalue1'}]
          }
        },
        {
          _id: 'org.couchdb.user:member2',
          data: {
            publicKeys: [{name: 'not-moirai', key: 'keyvalue2'}]
          }
        },
        {
          _id: 'org.couchdb.user:member3',
          data: {
            publicKeys: []
          }
        },
        {
          _id: 'org.couchdb.user:member3',
          data: {
            publicKeys: [
              {name: 'moirai', key: 'keyvalue4'},
              {name: 'moirai', key: 'keyvalue4.2'}
            ]
          }
        }
      ]))
    },
    teams: {
      getAllTeamRolesForUser: jasmine.createSpy('getAllTeamRolesForUser').andReturn(
        Promise.resolve([{team: 'team1Obj'}, {team: 'team2Obj'}])
      )
    }
  }
  this.validation = {}
  this.config = {
    RESOURCES:
      MOIRAI: {}
  }
  this.couch_utils = {
    conf: this.config
    nano_system_user: jasmine.createSpy('nano_system_user').andReturn('couchClient')
  }
  this.moirai = moirai(this.api, this.validation, this.couch_utils)


describe 'setClusterKeys', () ->
  beforeEach beforeEvery

  it 'sends the cluster and keys to the moirai API', (done) ->
    spyOn(this.moirai.testing.moiraiClient, 'put').andReturn(Promise.resolve())
    keys = ['key1', 'key2']
    this.moirai.testing.setClusterKeys('clusterid', keys).then(() =>
      expect(this.moirai.testing.moiraiClient.put).toHaveBeenCalledWith({
        url: '/moirai/clusters/clusterid/keys',
        json: keys,
        body_only: true
      })
      done()
    )

describe 'getTeamKeys', () ->
  beforeEach () ->
    beforeEvery.apply(this)
    this.team =
      roles:
        admin:
          members: [
            'member1',
            'member2'
          ]
        member:
          members: [
            'member3',
            'member4'
          ]
      rsrcs:
        moirai:
          assets: [
            {
              id: 'ab38f',
              cluster_id: 'cluster_test1',
              name: 'test1',
            },
            {
              id: 'xy93d',
              cluster_id: 'cluster_test2',
              name: 'test2',
            },
          ]

  it 'calls getUsers', (done) ->
    this.moirai.testing.getTeamKeys(this.team).then(() =>
      userList = ['member1', 'member2', 'member3', 'member4']
      expect(this.api.users.getUsers).toHaveBeenCalledWith('couchClient', {names: userList}, 'promise')
      done()
    ).catch(done)

  it 'gets a valid key where the name is moirai', (done) ->
    this.moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue1')).toEqual(true)
      done()
    ).catch(done)

  it 'does not get a key if the name is not moirai', (done) ->
    this.moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue2')).toEqual(false)
      done()
    ).catch(done)

  it 'only gets one moirai key per person', (done) ->
    this.moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue4')).toEqual(true)
      expect(_.contains(result, 'keyvalue4.2')).toEqual(false)
      done()
    ).catch(done)

  it 'gets the appropriate number of keys', (done) ->
    this.moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(result.length).toEqual(2)
      done()
    ).catch(done)

describe 'setTeamKeys', () ->
  beforeEach () ->
    beforeEvery.apply(this)
    this.team =
      rsrcs:
        moirai:
          assets: [
            {
              id: 'ab38f',
              cluster_id: 'cluster_test1',
              name: 'test1',
            },
            {
              id: 'xy93d',
              cluster_id: 'cluster_test2',
              name: 'test2',
            },
          ]
    spyOn(this.moirai.testing, 'getTeamKeys').andReturn(Promise.resolve(['key1', 'key3']))
    spyOn(this.moirai.testing, 'setClusterKeys').andReturn(Promise.resolve())

  it 'calls getTeamKeys', (done) ->
    this.moirai.testing.setTeamKeys(this.team).then(() =>
      expect(this.moirai.testing.getTeamKeys).toHaveBeenCalledWith(this.team)
      done()
    )

  it 'calls setClusterKeys with cluster id and key list', (done) ->
    this.moirai.testing.setTeamKeys(this.team).then(() =>
      expect(this.moirai.testing.setClusterKeys.calls.length).toEqual(2)
      expect(this.moirai.testing.setClusterKeys).toHaveBeenCalledWith(
        'cluster_test1',
        ['key1', 'key3']
      )
      expect(this.moirai.testing.setClusterKeys).toHaveBeenCalledWith(
        'cluster_test2',
        ['key1', 'key3']
      )
      done()
    )

describe 'handleAddUser', () ->
  beforeEach beforeEvery
  it 'gets the team object and calls setTeamKeys', (done) ->
    handleAddUser = this.moirai.handlers.team['u+']
    spyOn(this.moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())

    handleAddUser({user: 'userid', role: 'member'}, 'team').then((resp) =>
      expect(this.moirai.testing.setTeamKeys).toHaveBeenCalledWith('team')
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

describe 'handleRemoveUser', () ->
  beforeEach beforeEvery
  it 'gets the team object and calls setTeamKeys', (done) ->
    handleRemoveUser = this.moirai.handlers.team['u-']
    spyOn(this.moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())

    handleRemoveUser({user: 'userid', role: 'member'}, 'team').then((resp) =>
      expect(this.moirai.testing.setTeamKeys).toHaveBeenCalledWith('team')
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

describe 'removeCluster', () ->
  beforeEach beforeEvery
  it 'calls the moirai API to remove the cluster', (done) ->
    spyOn(this.moirai.testing.moiraiClient, 'del').andReturn(Promise.resolve())
    this.moirai.testing.removeCluster('testClusterId').then(() =>
      expect(this.moirai.testing.moiraiClient.del).toHaveBeenCalledWith('/moirai/clusters/testClusterId')
      done()
    )

describe 'handleRemoveCluster', () ->
  beforeEach beforeEvery
  it 'calls removeCluster', (done) ->
    handleRemoveCluster = this.moirai.handlers.team.self['a-']
    spyOn(this.moirai.testing, 'removeCluster').andReturn(Promise.resolve())

    handleRemoveCluster({asset: {cluster_id: 'clusterId'}}, 'team').then((resp) =>
      expect(this.moirai.testing.removeCluster).toHaveBeenCalledWith('clusterId')
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

describe 'handleAddCluster', () ->
  beforeEach beforeEvery
  it 'gets keys from getTeamKeys, calls setClusterKeys', (done) ->
    handleAddCluster = this.moirai.handlers.team.self['a+']
    spyOn(this.moirai.testing, 'setClusterKeys').andReturn(Promise.resolve())
    testKeys = ['key1', 'key2']
    spyOn(this.moirai.testing, 'getTeamKeys').andReturn(Promise.resolve(testKeys))

    handleAddCluster({asset: {cluster_id: 'cluster_id'}}, 'team').then((resp) =>
      expect(this.moirai.testing.getTeamKeys).toHaveBeenCalledWith('team')
      expect(this.moirai.testing.setClusterKeys).toHaveBeenCalledWith('cluster_id', testKeys)
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

describe 'handleAddData', () ->
  beforeEach () ->
    beforeEvery.apply(this)
    spyOn(this.moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())
    this.event = {data: {publicKeys: ['key']}}
    this.user = {name: 'user_name'}

  it 'calls getAllTeamRolesForUser', (done) ->
    handleAddData = this.moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) =>
      expect(this.api.teams.getAllTeamRolesForUser.calls.length).toEqual(1)
      expect(this.api.teams.getAllTeamRolesForUser).toHaveBeenCalledWith('user_name')
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

  it 'calls setTeamKeys', (done) ->
    handleAddData = this.moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) =>
      expect(this.moirai.testing.setTeamKeys.calls.length).toEqual(2)
      expect(this.moirai.testing.setTeamKeys).toHaveBeenCalledWith('team1Obj')
      expect(this.moirai.testing.setTeamKeys).toHaveBeenCalledWith('team2Obj')
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

  it 'does nothing if publicKeys not defined', (done) ->
    this.event.data = {sampleData: 'test'}
    handleAddData = this.moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) =>
      expect(this.moirai.testing.setTeamKeys.calls.length).toEqual(0)
      expect(resp).toBeUndefined()
      done()
    ).catch(done)

describe 'getOrCreateAsset', () ->
  beforeEach () ->
    beforeEvery.apply(this)
    spyOn(this.moirai.testing.moiraiClient, 'post').andCallFake((assetData, team) ->
      return Promise.resolve({
        _id: 'cluster_id'
        name: assetData.json.name
      })
    )
    this.team =
      name: 'team1 name!'
      rsrcs:
        moirai:
          assets: [
            id: "ab38f",
            cluster_id: 'cluster_test1',
            name: "test1",
          ]
    this.actor =
      data:
        username: 'actorName'
        email: 'emailAddress'

  it 'does nothing if the cluster already exists', (done) ->
    this.moirai.getOrCreateAsset({name: 'test1'}, this.team, this.actor).then((resp) =>
      expect(this.moirai.testing.moiraiClient.post).not.toHaveBeenCalled()
      expect(resp).toBeUndefined()
      done()
    )

  it "gets/creates a repo, and returns the details to store in couch", (done) ->
    this.moirai.getOrCreateAsset({new: 'app name123'}, this.team, this.actor).then((resp) =>
      expect(this.moirai.testing.moiraiClient.post).toHaveBeenCalledWith({
        url: '/moirai/clusters',
        json: {
          name: 'app name123'
          instances: [{
            tags: {
              Name: 'moirai-team1-name-app-name123'
              Application: 'app name123'
              BusinessOwner: 'team1 name!'
              Creator: this.actor.data.username
            }
          }]
        },
        body_only: true
      })
      expect(resp).toEqual({cluster_id: 'id', name: 'app name123'})
      done()
    ).catch((err) ->
      done(err)
    )
