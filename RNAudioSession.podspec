
Pod::Spec.new do |s|
  s.name         = "RNAudioSession"
  s.version      = "1.0.0"
  s.summary      = "RNAudioSession"
  s.description  = <<-DESC
                  RNAudioSession
                   DESC
  s.homepage     = "https://github.com/AmbiFi/react-native-audio-session.git"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/AmbiFi/react-native-audio-session.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m}"
  s.requires_arc = true
  s.frameworks = 'AVFoundation'

  s.dependency "React"
  #s.dependency "others"

end

  
