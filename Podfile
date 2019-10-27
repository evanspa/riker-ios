source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.1'

use_frameworks!
inhibit_all_warnings!

target "Riker" do
  pod 'ReactiveCocoa', '2.5'
  pod 'AFNetworking', '2.6.3'
  pod 'CocoaLumberjack'
  pod 'MBProgressHUD'
  pod 'FlatUIKit'
  pod 'UICKeyChainStore'
  pod 'IQKeyboardManager'
  pod 'BlocksKit'
  pod 'CHCSVParser'
  pod 'DateTools'
  pod 'FormatterKit'
  pod 'FMDB'
  pod 'Charts'
  pod 'Stripe'
  pod 'TNRadioButtonGroup'
  pod 'Firebase/Core'
  pod 'Firebase/Performance'
  pod 'Firebase/DynamicLinks'
  pod 'iCarousel'
  pod 'PINCache'
  pod 'SVPullToRefresh'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'FacebookCore'
  pod 'FBSDKLoginKit'
  pod 'Toast'

  post_install do |installer| # https://github.com/danielgindi/Charts/issues/3647
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        if target.name == 'Charts'
          config.build_settings['SWIFT_VERSION'] = '4.2'
        else
          config.build_settings['SWIFT_VERSION'] = '4.1'
        end
      end
    end
  end
end
