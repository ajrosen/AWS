[![Gem Version](https://badge.fury.io/rb/mkstack.svg)](https://badge.fury.io/rb/mkstack)

Merge multiple CloudFormation template files into a single template.
Each file may be in either JSON or YAML format.

Get started with *template = MkStack::Template.new*

## ERB

By default all files are run through an ERB (Embedded RuBy) processor.

    <% desc = "awesome" %>

    AWSTemplateFormatVersion: "2010-09-09"
    Description: My <%= desc %> CloudFormation template

It is safe to leave this enabled.  If a file doesn't have any ERB tags
it is passed through untouched.

## Include

MkStack searches each file for a section named **Include**, which should
be a list of filenames.  These function the same as adding the listed
files on the command line.

### JSON

    "Include" : [
      "foo.yaml",
      "bar.json"
    ]

### YAML

    Include:
      - foo.yaml
      - bar.json

## ERB and Include working together

MkStack uses a single *binding* for all files.  This allows ERB tags
defined in one file to be referenced in subsequent files.

### foo.yaml

    Include:
      - bar.json

    <% tags_json = %q{
         "Tags": [
           { "Key" : "application", "Value" : "mkstack" }
         ]
       }
    %>

### bar.json

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

Note that foo.yaml is processed *before* bar.json.
