#!/usr/bin/env ruby

require_relative '../lib/seal'
require_relative '../lib/team_builder'

if !Date.today.saturday? && !Date.today.sunday?
  teams = TeamBuilder.build(env: ENV)
  Seal.new(teams).bark(mode: ARGV[0])
end
