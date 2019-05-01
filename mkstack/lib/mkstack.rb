require_relative "mkstack/template"

=begin rdoc

Merge multiple CloudFormation template files into a single template.
Each file may be in either JSON or YAML format.

Get started with <i>template = MkStack::Template.new</i>

== ERB

By default all files are run through an ERB (Embedded RuBy) processor.
 
  <% desc = "awesome" %>

  AWSTemplateFormatVersion: "2010-09-09"
  Description: My <%= desc %> CloudFormation template

It is safe to leave this enabled.  If a file doesn't have any ERB tags
it is passed through untouched.

== Include

MkStack searches each file for a section named <b>Include</b>, which should
be a list of filenames.  These function the same as adding the listed
files on the command line.

=== JSON

  "Include" : [
    "foo.yaml",
    "bar.json"
  ]

=== YAML

  Include:
    - foo.yaml
    - bar.json

== ERB and Include working together

MkStack uses a single <i>binding</i> for all files.  This allows ERB
tags defined in one file to be referenced in subsequent files.

=== foo.yaml

  Include:
    - bar.json

  <% tags_json = %q{
       "Tags": [
         { "Key" : "application", "Value" : "mkstack" }
       ]
     }
  %>

=== bar.json

  {
    "Resources" : {
      "sg": {
        "Type" : "AWS::EC2::SecurityGroup",
        "Properties" : {
          "GroupDescription" : { "Fn::Sub" : "Security Group for ${application}" }
          <%= tags_json %>
        }
      }
    }
  }

Note that foo.yaml is processed <i>before</i> bar.json.

== See Also

  MkStack::Template
  MkStack::Section
=end

module MkStack
end
