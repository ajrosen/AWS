require_relative "section"

require "erb"
require "json"
require "yaml"

module MkStack
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
        "Mappings"   => Section.new("Mappings",   Hash, 100),
        "Metadata"   => Section.new("Metadata",   Hash, nil),
        "Outputs"    => Section.new("Outputs",    Hash, 60),
        "Parameters" => Section.new("Parameters", Hash, 60),
        "Resources"  => Section.new("Resources",  Hash, nil),
        "Transform"  => Section.new("Transform",  Hash, nil),
      }
      @limit = 51200

      # Keep track of parsed files to avoid loops
      @parsed = {}

      # Save a binding so ERB can reuse it instead of creating a new one
      # every time we load a file.  This allows ERB code in one file to
      # be referenced in another.
      @binding = binding

      # See add_domain_types
      @yaml_domain = "mlfs.org,2020"
      @global_tag = "tag:#{@yaml_domain}:"
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
        add_domain_types
        cfn = YAML.load(contents)
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
        # Strip enclosing quotes around tags and revert tags to their short form
        # And keep Psych from splitting "long" lines
        to_hash.to_yaml({ line_width: -1 }).gsub(/"(#{@global_tag}[^"]+?)"/, '\1').gsub("#{@global_tag}", "!")
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
    # Define YAML domains to handle CloudFormation intrinsic
    # functions.
    #
    # CloudFormation uses <b>!</b> to denote the YAML short form of
    # intrinsic functions, which is the same prefix YAML uses for
    # local tags.  The default handler strips undefined local tags,
    # leaving just the value.
    #
    # This puts the tags back, but in global tag format.  The global
    # tag prefix is converted back to <b>!</b> on output.
    #
    # Using the short form will force the output to be in YAML format.
    def add_domain_types
      functions = [
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
        YAML::add_domain_type(@yaml_domain, function) do |type, val|
          unless @format.eql?("yaml")
            $logger.debug "Setting output to YAML for short form intrinsic function !#{function}"
            @format = "yaml"
          end

          (function.eql?("Sub") and val.is_a?(String))? "#{type} \"#{val}\"" : "#{type} #{val}"
        end
      end
    end
  end
end
