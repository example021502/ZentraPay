#import "SwiftPrivyPlugin.h"
#if __has_include(<privy_flutter/privy_flutter-Swift.h>)
#import <privy_flutter/privy_flutter-Swift.h>
#else
#import "privy_flutter-Swift.h"
#endif

@implementation SwiftPrivyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    [SwiftPrivyPlugin registerWithRegistrar:registrar];
}
@end