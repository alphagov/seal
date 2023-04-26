#!/usr/bin/env ruby

require_relative '../lib/seal'
require_relative '../lib/team_builder'

if !Date.today.saturday? && !Date.today.sunday?
  teams = TeamBuilder.build(env: ENV, team_name: ARGV[0])
  Seal.new(teams).bark(mode: ARGV[1])
end
