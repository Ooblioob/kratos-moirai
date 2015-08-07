moirai = require('../lib/authorization')

describe '_is_moirai_team_admin', () ->
  beforeEach () ->
    this.auth = {
      _is_team_admin: jasmine.createSpy('_is_team_admin'),

    }
    this.moirai = moirai({auth: this.auth})

  it 'returns true if the user is a team admin', () ->
    this.auth._is_team_admin.andReturn(true)

    cut = this.moirai._is_moirai_team_admin

    actual = cut('actor', 'team')

    expect(this.auth._is_team_admin).toHaveBeenCalledWith('actor', 'team')
    expect(actual).toBe(true)

  it 'returns false if the user is not a team admin', () ->
    this.auth._is_team_admin.andReturn(false)

    cut = this.moirai._is_moirai_team_admin

    actual = cut('actor', 'team')

    expect(actual).toBe(false)


describe 'add_team_asset', () ->
  beforeEach () ->
    this.auth = {
      kratos:
        _is_kratos_admin: jasmine.createSpy('_is_kratos_admin'),

    }
    this.moirai = moirai({auth: this.auth})
    spyOn(this.moirai, '_is_moirai_team_admin')

  it 'allowed when user is a kratos admin', () ->

    this.auth.kratos._is_kratos_admin.andReturn(true)

    cut = this.moirai.add_team_asset

    actual = cut('actor', 'team')

    expect(this.auth.kratos._is_kratos_admin).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

  it 'allowed when user is a moirai team admin and a moirai user', () ->
    this.auth.kratos._is_kratos_admin.andReturn(false)
    this.moirai._is_moirai_team_admin.andReturn(true)
    cut = this.moirai.add_team_asset

    actual = cut('actor', 'team')

    expect(this.moirai._is_moirai_team_admin).toHaveBeenCalledWith('actor', 'team')
    expect(actual).toBe(true)

  it 'not allowed when the user is neither a (moirai team admin and moirai user) nor a kratos admin', () ->
    this.auth.kratos._is_kratos_admin.andReturn(false)
    this.moirai._is_moirai_team_admin.andReturn(false)
    cut = this.moirai.add_team_asset

    actual = cut('actor', 'team')

    expect(actual).toBe(false)

describe 'remove_team_asset', () ->
  beforeEach () ->
    this.auth = {
      kratos:
        _is_kratos_admin: jasmine.createSpy('_is_kratos_admin'),

    }
    this.moirai = moirai({auth: this.auth})
    spyOn(this.moirai, '_is_moirai_team_admin')

  it 'allowed when user is a kratos admin', () ->

    this.auth.kratos._is_kratos_admin.andReturn(true)

    cut = this.moirai.remove_team_asset

    actual = cut('actor', 'team')

    expect(this.auth.kratos._is_kratos_admin).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

  it 'allowed when user is a moirai team admin and a moirai user', () ->
    this.auth.kratos._is_kratos_admin.andReturn(false)
    this.moirai._is_moirai_team_admin.andReturn(true)

    cut = this.moirai.remove_team_asset

    actual = cut('actor', 'team')

    expect(this.moirai._is_moirai_team_admin).toHaveBeenCalledWith('actor', 'team')
    expect(actual).toBe(true)

  it 'not allowed when the user is neither a (moirai team admin and moirai user) nor a kratos admin', () ->
    this.auth.kratos._is_kratos_admin.andReturn(false)
    this.moirai._is_moirai_team_admin.andReturn(false)

    cut = this.moirai.remove_team_asset

    actual = cut('actor', 'team')

    expect(actual).toBe(false)


describe 'add_resource_role', () ->
  beforeEach () ->
    this.auth = {
      is_kratos_system_user: jasmine.createSpy('is_kratos_system_user'),
    }
    this.moirai = moirai({auth: this.auth})

  it 'allowed when the user is a super admin', () ->
    this.auth.is_kratos_system_user.andReturn(true)

    cut = this.moirai.add_resource_role

    actual = cut('actor', 'team')

    expect(this.auth.is_kratos_system_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

  it 'now allowed when the user is not a super admin', () ->
    this.auth.is_kratos_system_user.andReturn(false)

    cut = this.moirai.add_resource_role

    actual = cut('actor', 'team')

    expect(this.auth.is_kratos_system_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(false)

describe 'remove_resource_role', () ->
  beforeEach () ->
    this.auth = {
      is_kratos_system_user: jasmine.createSpy('is_kratos_system_user'),
    }
    this.moirai = moirai({auth: this.auth})

  it 'allowed when the user is a super admin', () ->
    this.auth.is_kratos_system_user.andReturn(true)

    cut = this.moirai.remove_resource_role

    actual = cut('actor', 'team')

    expect(this.auth.is_kratos_system_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

  it 'now allowed when the user is not a super admin', () ->
    this.auth.is_kratos_system_user.andReturn(false)

    cut = this.moirai.remove_resource_role

    actual = cut('actor', 'team')

    expect(this.auth.is_kratos_system_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(false)
