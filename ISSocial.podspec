Pod::Spec.new do |s|
  s.name     = 'ISSocial'
  s.version  = '0.1.1'
  s.license  = 'MIT'
  s.summary  = 'Social networks connection library.'
  s.source   = { :git => 'git@bitbucket.org:Infoshell/issocial.git', :branch => "develop",  :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'ISSocial/*.h'
  s.source_files = 'ISSocial/ISSocial.h'

  s.subspec 'Core' do |ss|
    ss.source_files = '*.{h,m}','Categories/*.{h,m}','Services/*.{h,m}','SocialObjects/*.{h,m}','System/*.{h,m}' 
    ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.osx.frameworks = 'CoreServices'
  end

  s.subspec 'Facebook' do |ss|
    ss.source_files = 'SocialConnectors/Facebook/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'GooglePlus' do |ss|
    ss.source_files = 'SocialConnectors/GooglePlus/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'Instagram' do |ss|
    ss.source_files = 'SocialConnectors/Instagram/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'Odnoklassniki' do |ss|
    ss.source_files = 'SocialConnectors/Odnoklassniki/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'Twitter' do |ss|
    ss.source_files = 'SocialConnectors/Twitter/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'Vkontakte' do |ss|
    ss.source_files = 'SocialConnectors/Vkontakte/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end
  
end