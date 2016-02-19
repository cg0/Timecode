#define settingsPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/pe.nn.connor.timecode.plist"]

%hook SBDeviceLockController

- (_Bool)attemptDeviceUnlockWithPassword:(id)arg1 appRequested:(_Bool)arg2{
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

	bool enabled = [[prefs objectForKey:@"enabled"] boolValue];
	NSString *passcode = [prefs objectForKey:@"passcode"];
	bool allowRealCode = [[prefs objectForKey:@"allowDefaultCode"] boolValue];
	int offset = [[prefs objectForKey:@"offset"] intValue];
	bool reversed = [[prefs objectForKey:@"reversed"] boolValue];
	bool negativeOffset = [[prefs objectForKey:@"negativeOffset"] boolValue];
	bool betterTime = [[prefs objectForKey:@"24hour"] boolValue];
	bool debugEnabled = [[prefs objectForKey:@"debug"] boolValue];
	[prefs release];

	if(enabled && (passcode != nil && [passcode length] > 0)){
		NSString *code = arg1;
		NSDate *now = [NSDate date];
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		NSString *localeString = @"en_UK";
		NSString *dateFormat = @"HHmm";
		if(!betterTime){
			localeString = @"en_US";
			dateFormat = @"hhmm";
		}
		[outputFormatter setDateFormat:dateFormat];

		NSLocale *locale = [[NSLocale alloc]
                     initWithLocaleIdentifier:localeString];
		[outputFormatter setLocale:locale];
		NSString *newDateString = [outputFormatter stringFromDate:now];
		NSString *originalString = newDateString;
		if(reversed){
			NSMutableString *reversedString = [NSMutableString string];
			NSInteger charIndex = [newDateString length];
			while (charIndex > 0) {
    		charIndex--;
    		NSRange subStrRange = NSMakeRange(charIndex, 1);
    		[reversedString appendString:[newDateString substringWithRange:subStrRange]];
			}
			newDateString = reversedString;
		}
		int intCode = [newDateString intValue];
		if(negativeOffset){
			offset = offset - (offset * 2);
		}
		intCode = intCode + offset;
		newDateString = [NSString stringWithFormat:@"%d", intCode];
		if([newDateString length] < 4){
			for(int i=1; i < ([newDateString length] - 4); i++){
				newDateString = [NSString stringWithFormat:@"0%@", newDateString];
			}
		}
		[outputFormatter release];
		if(debugEnabled){
			if(code == NULL){
				code = @"Touch ID";
			}
			NSString *debug = [NSString stringWithFormat:@"Time data: %1$@\nTime code: %2$@\nPasscode: %3$@\nEntered passcode: %4$@\nOffset: %5$d", originalString, newDateString, passcode, code, offset];
			UIAlertView *test = [[UIAlertView alloc]
				initWithTitle: @"TimeCode Debug"
				message: debug
				delegate: nil
				cancelButtonTitle: @"OK"
				otherButtonTitles: nil
			];
			[test show];
			[test release];
		}
		if([code isEqualToString: newDateString]){
			return %orig(passcode, arg2);
		}else if([code isEqualToString: passcode] && allowRealCode){
			return %orig;
		}else{
			if(allowRealCode){
				return %orig(arg1, arg2);
			}else{
				return %orig(nil, arg2);
			}
		}
	}else{
		return %orig;
	}

}

%end

//Used to display first time install message
%hook SpringBoard

-(void) applicationDidFinishLaunching:(id)arg1{
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
	NSString* passcode = [prefs objectForKey:@"passcode"];
	[prefs release];
	if(passcode == nil || [passcode length] == 0){
		UIAlertView *alert = [[UIAlertView alloc]
			initWithTitle: @"Welcome to TimeCode"
			message: @"Thanks for installing TimeCode! :D\nPlease set your passcode in the perference panel"
			delegate: nil
			cancelButtonTitle: @"OK"
			otherButtonTitles: nil
		];
		[alert show];
		[alert release];
	}
	%orig;
}

%end
