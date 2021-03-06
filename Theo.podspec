Pod::Spec.new do |s|
  s.name         = "Theo"
  s.version      = "3.1.2"
  s.summary      = "Open Source Neo4j library for iOS"

  s.description  = <<-DESC
    Theo is an open-source framework written in Swift that provides an interface for interacting with Neo4j.

    Features:
    - CRUD operations for Nodes and Relationships
    - Transaction statement execution
    - Bolt support
DESC

  s.homepage     = "https://github.com/GraphStory/neo4j-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.authors             = { "Cory Wiles" => "corywiles@icloud.com",
                            "Niklas Saers" => "niklas@saers.com" }

  s.source       = { :git => "https://github.com/GraphStory/neo4j-ios.git", :tag => "v#{s.version}" }

  s.source_files  = "Classes", "Sources/**/*.swift"
  
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"
  
  s.dependency 'BoltProtocol', '~> 0.9.0'
  
end
