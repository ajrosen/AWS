require_relative "section"

require "erb"
require "json"
require "yaml"

module MkStack
  ##################################################
  # A class to represent undefined local tags.
  #
  # CloudFormation uses <b>!</b> to denote the YAML short form of
  # intrinsic functions, which is the same prefix YAML uses for local
  # tags.  The default handler strips undefined local tags, leaving
  # just the value.
  #
  # Loading a YAML file will force the output to be in YAML format.

  class IntrinsicShort
    def init_with(coder)
      @coder = coder
    end

    def encode_with(coder)
      coder.tag = @coder.tag

      coder.map = @coder.map if @coder.type == :map
      coder.scalar = @coder.scalar if @coder.type == :scalar
      coder.seq = @coder.seq if @coder.type == :seq
    end
  end

  ##################################################
  # A CloudFormation template
  class Template
    attr_reader :sections, :limit, :format

    def initialize(format = "json", argv = nil)
      @format = format

      @sections = {
        "AWSTemplateFormatVersion" => Section.new("AWSTemplateFormatVersion", String, nil),
        "Description" => Section.new("Description", String, 1024),

        "Conditions" => Section.new("Conditions", Hash, nil),
        "Mappings"   => Section.new("Mappings",   Hash, 200),
        "Metadata"   => Section.new("Metadata",   Hash, nil),
        "Outputs"    => Section.new("Outputs",    Hash, 200),
        "Parameters" => Section.new("Parameters", Hash, 200),
        "Resources"  => Section.new("Resources",  Hash, 500),
        "Transform"  => Section.new("Transform",  Hash, nil),
      }
      @limit = 51200

      # Keep track of parsed files to avoid loops
      @parsed = {}

      # Save a binding so ERB can reuse it instead of creating a new one
      # every time we load a file.  This allows ERB code in one file to
      # be referenced in another.
      @binding = binding
    end

    # Shorthand accessor for template sections
    def [](section); @sections[section]; end

    # Return the length of the entire template
    def length; to_json.to_s.length; end

    # Check if the template exceeds the AWS limit
    def exceeds_limit?; limit && length > limit; end


    #########################
    # Merge contents of a file
    def merge(file, erb)
      contents = load(file, erb)

      begin
        # Try JSON
        cfn = JSON.load(contents)
      rescue Exception => e
        # Try YAML
        add_tags
        cfn = YAML.safe_load(contents, [IntrinsicShort])
        @format = "yaml"
      end

      # Merge sections that are present in the file
      @sections.each { |name, section| section.merge(cfn[name]) if cfn[name] }

      # Look for Includes and merge them
      # Files are Included relative to the file with the Include directive
      cfn["Include"].each do |file|
        Dir.chdir(File.dirname(file)) { self.merge(File.basename(file), erb) }
      end if cfn["Include"]
    end


    #########################
    # Call ValidateTemplate[https://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_ValidateTemplate.html]
    def validate
      require "aws-sdk-cloudformation"
      Aws::CloudFormation::Client.new.validate_template({ template_body: pp })
    end


    #########################
    # Format contents
    def pp
      case @format
      when "json"
        to_hash.to_json
      when "yaml"
        to_hash.to_yaml({ line_width: -1 }) # Keep Psych from splitting "long" lines
      else
        to_hash
      end
    end

    private

    #########################
    # Create a hash of each populated section's contents
    def to_hash
      h = Hash.new
      @sections.each { |k, v| h[k] = v.contents if v.length > 0 }
      h
    end


    #########################
    # Read file and (optionally) perform ERB processing on it
    def load(file, erb = true)
      path = File.expand_path(file)
      raise KeyError if @parsed.has_key?(path)

      $logger.info { "Loading #{file}" } if $logger

      contents = File.read(file)
      contents = ERB.new(contents).result(@binding) if erb

      @parsed[path] = true

      return contents
    end


    #########################
    # List of intrinsic functions that look like undefined local tags
    def add_tags
      [
        "Base64",
        "Cidr",
        "FindInMap",
        "GetAtt",
        "GetAZs",
        "ImportValue",
        "Join",
        "Ref",
        "Select",
        "Split",
        "Transform",
        "And",
        "Equals",
        "If",
        "Not",
        "Or",
        "Sub",
      ].each do |function|
        YAML::add_tag("!#{function}", IntrinsicShort)
      end
    end
  end
end
