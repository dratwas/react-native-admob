#import "RNAdMobInterstitial.h"
#import <React/RCTConvert.h>
#import <CoreLocation/CoreLocation.h>

@implementation RNAdMobInterstitial {
  GADInterstitial  *_interstitial;
  NSString *_adUnitID;
  NSString *_testDeviceID;
  NSString *_contentUrl;
  NSCalendar *_birthday;
  GADGender *_gender;
  CLLocation *_location;
  BOOL _childDirected;
  RCTResponseSenderBlock _requestAdCallback;
  RCTResponseSenderBlock _showAdCallback;
}

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

#pragma mark exported methods

RCT_EXPORT_METHOD(setAdUnitID:(NSString *)adUnitID)
{
  _adUnitID = adUnitID;
}

RCT_EXPORT_METHOD(setTestDeviceID:(NSString *)testDeviceID)
{
  _testDeviceID = testDeviceID;
}

RCT_EXPORT_METHOD(setChildDirected:(BOOL *)childDirected)
{
  _childDirected = childDirected;
}

RCT_EXPORT_METHOD(setContentUrl:(NSString *)contentUrl)
{
  _contentUrl = contentUrl;
}

RCT_EXPORT_METHOD(setGender:(NSString *)gender)
{
  if ([gender isEqualToString:@"male"]) {
    _gender = kGADGenderMale;
  } else {
    _gender = kGADGenderFemale;
  }
}

RCT_EXPORT_METHOD(setLocation:(NSDictionary *)coordinates)
{
  if (coordinates[@"lat"] && coordinates[@"long"]) {
    _location = [[CLLocation alloc]
                 initWithLatitude:[RCTConvert double:coordinates[@"lat"]]
                 longitude:[RCTConvert double:coordinates[@"long"]]];
  }
}

RCT_EXPORT_METHOD(setBirthday:(NSDictionary *)birthday)
{
  if (birthday[@"month"] && birthday[@"day"] && birthday[@"year"]) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.month = [RCTConvert NSInteger:birthday[@"month"]];
    components.day = [RCTConvert NSInteger:birthday[@"day"]];
    components.year = [RCTConvert NSInteger:birthday[@"year"]];
    _birthday = [[NSCalendar currentCalendar] dateFromComponents:components];
  }
}

RCT_EXPORT_METHOD(setTargetingData:(NSDictionary *)targetingData)
{
  if (targetingData[@"gender"]) {
    [self setGender:targetingData[@"gender"]];
  }

  if (targetingData[@"month"] && targetingData[@"day"] && targetingData[@"year"]) {
    [self setBirthday:targetingData];
  }

  if (targetingData[@"lat"] && targetingData[@"long"]) {
    [self setLocation:targetingData];
  }

  if (targetingData[@"childDirected"]) {
    [self setChildDirected:[RCTConvert BOOL:targetingData[@"childDirected"]]];
  }

  if (targetingData[@"contentUrl"]) {
    [self setContentUrl:targetingData[@"contentUrl"]];
  }
}

RCT_EXPORT_METHOD(requestAd:(RCTResponseSenderBlock)callback)
{
  if ([_interstitial hasBeenUsed] || _interstitial == nil) {
    _requestAdCallback = callback;

    _interstitial = [[GADInterstitial alloc] initWithAdUnitID:_adUnitID];
    _interstitial.delegate = self;

    GADRequest *request = [self getRequestWithTargeting];

    [_interstitial loadRequest:request];
  } else {
    callback(@[@"Ad is already loaded."]); // TODO: make proper error via RCTUtils.h
  }
}


RCT_EXPORT_METHOD(showAd:(RCTResponseSenderBlock)callback)
{
  if ([_interstitial isReady]) {
    _showAdCallback = callback;
    [_interstitial presentFromRootViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
  }
  else {
    callback(@[@"Ad is not ready."]); // TODO: make proper error via RCTUtils.h
  }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
  callback(@[[NSNumber numberWithBool:[_interstitial isReady]]]);
}


#pragma mark delegate events

- (GADRequest *)getRequestWithTargeting {
  GADRequest *request = [GADRequest request];
  if (_gender) {
    request.gender = _gender;
  }
  if (_birthday) {
    request.birthday = _birthday;
  }
  if (_location) {
    [request setLocationWithLatitude:_location.coordinate.latitude
                           longitude:_location.coordinate.longitude
                            accuracy:_location.horizontalAccuracy];
  }
  if (_childDirected) {
    [request tagForChildDirectedTreatment:YES];
  }
  if (_contentUrl) {
    request.contentURL = _contentUrl;
  }
  if (_testDeviceID) {
    if ([_testDeviceID isEqualToString:@"EMULATOR"]) {
      request.testDevices = @[kGADSimulatorID];
    } else {
      request.testDevices = @[_testDeviceID];
    }
  }
  return request;
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad {
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"interstitialDidLoad" body:nil];
  _requestAdCallback(@[[NSNull null]]);
}

- (void)interstitial:(GADInterstitial *)interstitial
didFailToReceiveAdWithError:(GADRequestError *)error {
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"interstitialDidFailToLoad" body:@{@"name": [error description]}];
  _requestAdCallback(@[[error description]]);
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)ad {
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"interstitialDidOpen" body:nil];
  _showAdCallback(@[[NSNull null]]);
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"interstitialDidClose" body:nil];
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"interstitialWillLeaveApplication" body:nil];
}

@end
