lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'sack/version'

Gem::Specification.new do |s|
  s.name = %q{sack}
  s.version = Sack::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Megan Batty"]
  s.date = %q{2011-05-09}
  s.summary = %q{Stream-Oriented Rack}
  s.description = %q{Rack inverted so that you can:
* More easily stream results to the client.
* Manage thread pooling at the application level rather than it being a handler function.
* Get input streamed directly to you.
}
  s.email = %q{megan@stormbrew.ca}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "README.md",
    "Rakefile",
    "lib/sack.rb",
    "lib/sack/version.rb",
    "lib/sack/request_queue.rb",
    "lib/sack/server/thin.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/stormbrew/sack}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}

  s.add_development_dependency(%q<rspec>, ["~> 2.0"])
  s.add_development_dependency(%q<thin>)
  s.add_development_dependency(%q<thin_async>)
end

