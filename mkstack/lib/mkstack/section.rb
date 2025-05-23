module MkStack
  ##################################################
  # A CloudFormation template section
  class Section
    attr_reader :name, :limit
    attr_accessor :contents

    # * name: The section's name (Resources, Outputs, etc.)
    # * type: The section's type (Hash or String)
    # * limit: The AWS limit for this section, if any
    def initialize(name, type, limit = nil)
      @name = name
      @limit = limit

      @contents = type.new
    end

    # Merge or override a section snippet
    def merge(contents)
      # Hashes get merged
      return @contents.merge!(contents) if @contents.respond_to?(:merge!)

      # Arrays get concatenated or pushed
      if @contents.respond_to?(:push)
        return @contents.concat(contents) if contents.respond_to?(:push)
        return @contents.push(contents)
      end

      # Strings get copied
      @contents = contents
    end

    # Return the length of the section's contents
    def length; @contents.length; end

    # Check if the section exceeds the AWS limit
    def exceeds_limit?; @limit && length > @limit; end
  end
end
