module.exports = (validation) ->
  moirai = {
    add_team_asset: (actor, team) ->
      return moirai._can_manage_moirai_assets(actor, team)
    remove_team_asset: (actor, team) ->
      return moirai._can_manage_moirai_assets(actor, team)

    _is_moirai_team_admin: (actor, team) ->
        return validation.auth._is_team_admin(actor, team)

    _can_manage_moirai_assets: (actor, team) ->
      return validation.auth.kratos._is_kratos_admin(actor) or 
                   moirai._is_moirai_team_admin(actor, team)

    proxy:
      start: (actor, team) ->
        return moirai._can_manage_moirai_assets(actor, team)

      stop: (actor, team) ->
        return moirai._can_manage_moirai_assets(actor, team)
  }
