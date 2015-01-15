Pod::Spec.new do |s|
  s.name     = 'ISSocial'
  s.version  = '0.1.1'
  s.license  = 'MIT'
  s.summary  = 'Social networks connection library.'
  s.source   = { :git => 'git@bitbucket.org:Infoshell/issocial.git', :branch => "develop",  :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'ISSocial/*.h'
  s.source_files = 'ISSocial/*.h'

  s.subspec 'Core' do |ss|
    ss.source_files = 'ISSocial/*.{h,m}'
    ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.osx.frameworks = 'CoreServices'

    ss.dependency 'ReactiveCocoa', '~> 2.3'
    ss.dependency 'SDWebImage', '~> 3.7'
    ss.dependency 'RegexKitLite', '~> 4.0'
    ss.dependency 'AFNetworking', '~> 2.5'    

    ss.default_subspecs = 'Categories', 'Services', 'SocialObjects', 'System' 

    ss.subspec 'Categories' do |sss|
      sss.source_files = 'ISSocial/Categories/*.{h,m}'
      sss.public_header_files = 'ISSocial/Categories/*.h'
    end

    ss.subspec 'Services' do |sss|
      sss.source_files = 'ISSocial/Services/*.{h,m}'
    end

    ss.subspec 'SocialObjects' do |sss|
      sss.source_files = 'ISSocial/SocialObjects/*.{h,m}'
    end

    ss.subspec 'System' do |sss|
      sss.source_files = 'ISSocial/System/*.{h,m}'
    end

  end

  s.subspec 'Facebook' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/Facebook/*.{h,m}'
    ss.dependency 'ISSocial/Core'
    ss.dependency 'Facebook-iOS-SDK', '~> 3.0'
  end

  s.subspec 'GooglePlus' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/GooglePlus/*.{h,m}'
    ss.dependency 'ISSocial/Core'
    ss.dependency 'googleplus-ios-sdk', '~> 1.7'
  end

  s.subspec 'Instagram' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/Instagram/*.{h,m}'
    ss.dependency 'ISSocial/Core'
  end

  s.subspec 'Odnoklassniki' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/Odnoklassniki/*.{h,m}'
    ss.dependency 'ISSocial/Core'
    ss.default_subspecs = 'API','OKSdk'

    ss.subspec 'API' do |sss|
      sss.source_files = 'ISSocial/SocialConnectors/Odnoklassniki/ODKApi/*.{h,m}'
    end

    ss.subspec 'OKSdk' do |sss|
      sss.source_files = 'ISSocial/SocialConnectors/Odnoklassniki/OKSdk/**/*.{h,m}','ISSocial/SocialConnectors/Odnoklassniki/OKSdk/*.{h,m}'
      #ss.dependency 'SBJson', '~> 3.0'
    end
  end

  s.subspec 'Twitter' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/Twitter/*.{h,m}'
    ss.dependency 'ISSocial/Core'
    ss.dependency 'STTwitter', '~> 0.1'
    
  end

  s.subspec 'Vkontakte' do |ss|
    ss.source_files = 'ISSocial/SocialConnectors/Vkontakte/*.{h,m}'
    ss.dependency 'ISSocial/Core'
    ss.dependency 'VK-ios-sdk', '~> 1.0'
  end
  
end