#!/usr/bin/env ruby

require_relative '../lib/gem_version_checker'

GemVersionChecker.new.print_version_discrepancies
