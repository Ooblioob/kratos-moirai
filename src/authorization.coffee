module.exports = (validation) ->
  moirai = {
    add_team_asset: (actor, team) ->
      return validation.auth.kratos._is_kratos_admin(actor) or 
                   moirai._is_moirai_team_admin(actor, team)

    remove_team_asset: (actor, team) ->
      return validation.auth.kratos._is_kratos_admin(actor) or 
                   moirai._is_moirai_team_admin(actor, team)

    add_resource_role: (actor, role) ->
      return validation.auth.is_kratos_system_user(actor)

    remove_resource_role: (actor, role) ->
      return validation.auth.is_kratos_system_user(actor)

    _is_moirai_team_admin: (actor, team) ->
        return validation.auth._has_resource_role(actor, 'moirai', 'user') and
               validation.auth._is_team_admin(actor, team)
  }
