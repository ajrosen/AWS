Gem::Specification.new do |s|
  s.name	= "mkstack"
  s.version	= "1.2.0"
  s.summary	= "Merge multiple CloudFormation template files into a single template"
  s.description	= <<-EOF
Merge multiple CloudFormation template files into a single template.  Each file may be in either JSON or YAML format.  By default all files are run through an ERB (Embedded RuBy) processor.
EOF

  s.authors	= [ "Andy Rosen" ]
  s.email	= [ "ajr@corp.mlfs.org" ]
  s.homepage	= "https://github.com/ajrosen/AWS/tree/master/mkstack"
  s.licenses	= [ "GPL-3.0+" ]

  s.files	= Dir[ "mkstack.gemspec", "bin/*", "lib/**/*.rb" ]
  s.executables	= [ "mkstack" ]

  s.add_runtime_dependency "aws-sdk-cloudformation", "~> 1"
end
