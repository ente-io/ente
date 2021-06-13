#import "ImageScannerPlugin.h"
#import "PMPlugin.h"

@implementation ImageScannerPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
  PMPlugin *plugin = [PMPlugin new];
  [plugin registerPlugin:registrar];
}

@end
