Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.name         = "BuckarooBanzai"
  spec.version      = "0.5.0"
  spec.summary      = "A new way to do networking in Swift. That other one is old AF."

  
  spec.description  = <<-DESC
  This is a light-weight, highly expandable and wrappable network layer. It has a simple-to-use structure and can be used with unit tests without a server.
                   DESC

  spec.homepage     = "http://www.danielperson.com/BuckarooBanzai"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.license      = { :type => "MIT", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.author             = { "Daniel Person" => "daniel.person@yahoo.com" }
  

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.swift_versions = "5.0"
  spec.platform = :ios, "15.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.source       = { :git => "https://github.com/BonEvil/BuckarooBanzai.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.source_files  = "BuckarooBanzai", "BuckarooBanzai/**/*.{h,m,swift}"
  spec.public_header_files = "BuckarooBanzai/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.requires_arc = true


end
