# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

module Inspec
  class Error < StandardError; end

  # dependency resolution
  class CyclicDependencyError < Error; end
  class UnsatisfiedVersionSpecification < Error; end
end
