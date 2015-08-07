utils = require('pantheon-helpers').utils
Promise = require('pantheon-helpers').promise
_ = require('underscore')

# /teams/tools/moirai/<assetId>/start post
# /teams/tools/moirai/<assetId>/stop post


module.exports = (router, api, validation, couchUtils) ->
  doProxyAction = (proxyActionName, proxyActionFn) ->
    return (req, resp) ->
      orgDb = req.couch.use('org_' + req.params.orgId)
      teamPromise = api.teams.getTeam(orgDb, req.params.teamId)
      actorName = req.session.user
      actorPromise = utils.getActor(couchUtils, actorName)

      promise = Promise.all([actorPromise, teamPromise]).then(([actor, team]) ->
        assetId = req.params.assetId
        asset = _.findWhere(team.rsrcs.moirai.assets, {id: assetId})
        if not asset
          throw({code: 404, body: 'asset ' + assetId + ' does not exist'})

        validation.proxy_resource(actor, team, 'moirai', 'stop', asset)
        Promise.resolve([actor, team, action])
      ).then(([actor, team, action]) ->
        proxyActionFn(actor, team, action)
      )
      Promise.sendHttp(promise, resp)

  router.post(':assetId/start', doProxyAction('start', (actor, team, action) ->
    # TODO
  ))
  router.post(':assetId/stop', doProxyAction('stop', (actor, team, action) ->
    # TODO
  ))
