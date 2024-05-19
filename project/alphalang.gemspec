Gem::Specification.new do |spec|
  spec.name          = 'alphalang'
  spec.version       = '0.2.9'
  spec.authors       = ['mattias, victor']
  spec.email         = ['mattiasreuterskiold@gmail.com']
  spec.summary       = 'alphalanguage'
  spec.description   = 'Abstract Syntax Tree building language with a recursive descent parser'
  spec.homepage      = 'https://portfolio.reuterskiold.dev'

  spec.license       = 'MIT'

  spec.files         = Dir.glob('{bin/*,lib/**/*}') - %w[.gitignore Gemfile Gemfile.lock]
  spec.executables   = Dir.glob('bin/*').map{ |f| File.basename(f) }

  # dependecies
  spec.required_ruby_version = '>= 3.0.2'
  spec.add_dependency 'logger', '~> 1.5', '>= 1.5.0'
  spec.add_dependency 'optparse', '~> 0.3', '>= 0.3.0'
end
