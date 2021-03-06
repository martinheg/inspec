# encoding: utf-8
require 'inspec/dependencies/vendor_index'
require 'inspec/dependencies/requirement'
require 'inspec/dependencies/resolver'

module Inspec
  #
  # A DependencySet manages a list of dependencies for a profile.
  #
  # Currently this class is a thin wrapper interface to coordinate the
  # VendorIndex and the Resolver.
  #
  class DependencySet
    #
    # Return a dependency set given a lockfile.
    #
    # @param lockfile [Inspec::Lockfile] A lockfile to generate the dependency set from
    # @param cwd [String] Current working directory for relative path includes
    # @param vendor_path [String] Path to the vendor directory
    #
    def self.from_lockfile(lockfile, cwd, vendor_path)
      vendor_index = VendorIndex.new(vendor_path)
      dep_tree = lockfile.deps.map do |dep|
        Inspec::Requirement.from_lock_entry(dep, cwd, vendor_index)
      end

      dep_list = flatten_dep_tree(dep_tree)
      new(cwd, vendor_path, dep_list)
    end

    # This is experimental code to test the working of the
    # dependency loader - perform a proper dependency related search
    # in the future.
    #
    # Flatten tree because that is all we know how to deal with for
    # right now. Last dep seen for a given name wins right now.
    def self.flatten_dep_tree(dep_tree)
      dep_list = {}
      dep_tree.each do |d|
        dep_list[d.name] = d
        dep_list.merge!(flatten_dep_tree(d.dependencies))
      end
      dep_list
    end

    attr_reader :vendor_path
    attr_writer :dep_list
    # initialize
    #
    # @param cwd [String] current working directory for relative path includes
    # @param vendor_path [String] path which contains vendored dependencies
    # @return [dependencies] this
    def initialize(cwd, vendor_path, dep_list = nil)
      @cwd = cwd
      @vendor_path = vendor_path
      @dep_list = dep_list
    end

    def list
      @dep_list
    end

    def to_array
      return [] if @dep_list.nil?
      @dep_list.map do |_k, v|
        v.to_hash
      end.compact
    end

    #
    # 1. Get dependencies, pull things to a local cache if necessary
    # 2. Resolve dependencies
    #
    # @param dependencies [Gem::Dependency] list of dependencies
    # @return [nil]
    #
    def vendor(dependencies)
      return nil if dependencies.nil? || dependencies.empty?
      @vendor_index ||= VendorIndex.new(@vendor_path)
      @dep_list = Resolver.resolve(dependencies, @vendor_index, @cwd)
    end
  end
end
