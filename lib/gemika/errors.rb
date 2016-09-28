module Gemika
  class Error < StandardError; end
  class MissingGemfile < Error; end
  class MissingLockfile < Error; end
  class UnusableGemfile < Error; end
  class UnsupportedRuby < Error; end
  class MatrixFailed < Error; end
  class RSpecFailed < Error; end
end
