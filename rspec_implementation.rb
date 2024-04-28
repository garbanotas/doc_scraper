# Expected results

expect('string').to(have_size(2)) # => false
expect([1, 2, 3]).to include(3) # => true


# Implementation

def expect(obj)
  TestCase.new(obj)
end

def have_size(size)
  -> (obj) { obj.size == size }
end

def include(item)
  -> (obj) { obj.respond_to?(:include?) ? obj.include?(item) : false }
end

class TestCase
  def initialize(obj)
    @obj = obj
  end

  def to(matcher)
    matcher.call(@obj)
  end
end
