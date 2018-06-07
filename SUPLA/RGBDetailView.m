/*
 Copyright (C) AC SOFTWARE SP. Z O.O.
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "RGBDetailView.h"
#import "UIHelper.h"
#import "SAChannel+CoreDataClass.h"
#import "SAColorListItem+CoreDataClass.h"
#import "Database.h"
#import "SuplaApp.h"


#define MIN_REMOTE_UPDATE_PERIOD 0.25
#define MIN_UPDATE_DELAY 0.5

@implementation SARGBDetailView {
    int _brightness;
    int _colorBrightness;
    UIColor *_color;
    NSArray *_colorMarkers;
    NSArray *_brightnessMarkers;
    NSArray *_colorBrightnessMarkers;
    
    NSTimer *delayTimer1;
    NSTimer *delayTimer2;
    
    NSDate *_moveEndTime;
    NSDate *_remoteUpdateTime;

    
}

-(void)detailViewInit {
    
    if ( self.initialized == NO ) {
        
        delayTimer1 = nil;
        delayTimer2 = nil;
        
        _moveEndTime = [NSDate dateWithTimeIntervalSince1970:0];
        _remoteUpdateTime = _moveEndTime;
        
        self.cbPicker.delegate = self;
        
        [self.clPicker addItemWithColor:[UIColor whiteColor] andPercent:100];
        [self.clPicker addItem];
        [self.clPicker addItem];
        [self.clPicker addItem];
        [self.clPicker addItem];
        [self.clPicker addItem];
        self.clPicker.delegate = self;
        
        self.backgroundColor = [UIColor rgbDetailBackground];
        
        UIFont *font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                               forKey:NSFontAttributeName];
        
        [self.segControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
        
    }

    
    [super detailViewInit];
    
}

-(void)setBrightnessLabel:(int)brightness {
    
    [self.labelPercent setText:[NSString stringWithFormat:@"%i%%", (int)brightness]];
    self.stateBtn.selected = brightness > 0;
    
}

- (void)setColorLabel:(UIColor*)color {
    
    CGFloat red,green,blue,alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    red*=255;
    green*=255;
    blue*=255;
    
    [self.labelColorHEX setText:[NSString stringWithFormat:@"#%02X%02X%02X", (int)red, (int)green, (int)blue]];
    
}

- (void)showValues {
  
    if ( self.cbPicker.bwBrightnessWheelVisible == YES ) {
        
        if ( (int)self.cbPicker.brightness != (int)_brightness ) {
            self.cbPicker.brightness = (int)_brightness;
        }
        
        self.cbPicker.brightnessMarkers = _brightnessMarkers;
        [self setBrightnessLabel:_brightness];
        
    }
    
    if ( self.cbPicker.colorBrightnessWheelVisible == YES ) {
        
        if ( (int)self.cbPicker.brightness != (int)_colorBrightness ) {
            self.cbPicker.brightness = (int)_colorBrightness;
        };
        
        self.cbPicker.brightnessMarkers = _colorBrightnessMarkers;
        self.cbPicker.colorMarkers = _colorMarkers;
        [self setBrightnessLabel:_colorBrightness];
        
        self.cbPicker.color = _color;
        [self setColorLabel:_color];

    }
    
}

- (void)sendNewValues {
    
    if ( delayTimer1 != nil ) {
        [delayTimer1 invalidate];
        delayTimer1 = nil;
    }
    
    SASuplaClient *client = [SAApp SuplaClient];
    if ( client == nil || self.channelBase == nil ) return;
    
    double time = [_remoteUpdateTime timeIntervalSinceNow] * -1;
    
    int brightness = _brightness;
    int colorBrightness = _colorBrightness;
    UIColor *color = _color;
    
    if ( self.cbPicker.colorBrightnessWheelVisible ) {
        colorBrightness = self.cbPicker.brightness;
        color = self.cbPicker.color;
    } else if ( self.cbPicker.bwBrightnessWheelVisible ) {
        brightness = self.cbPicker.brightness;
    }
    
    if ( time >= MIN_REMOTE_UPDATE_PERIOD
        && [client channel:self.channelBase.remote_id setRGB:color colorBrightness:colorBrightness brightness:brightness] ) {
        
        _remoteUpdateTime = [NSDate date];
        _moveEndTime = [NSDate dateWithTimeIntervalSinceNow:2];
        
    } else {
        
        if ( time < MIN_REMOTE_UPDATE_PERIOD )
           time = MIN_REMOTE_UPDATE_PERIOD-time+0.001;
        else
           time = 0.001;
        
        delayTimer1 = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(timer1FireMethod:) userInfo:nil repeats:NO];
    }
    
}

- (void)showValuesWithDelay {
    
    if ( delayTimer2 != nil ) {
        [delayTimer2 invalidate];
        delayTimer2 = nil;
        return;
    }

    if ( self.cbPicker.moving == YES )
        return;
    
    double time = [_moveEndTime timeIntervalSinceNow] * -1;
    
    if ( time >= MIN_UPDATE_DELAY ) {
        [self showValues];
    } else {
        
        if ( time < MIN_UPDATE_DELAY )
            time = MIN_UPDATE_DELAY-time+0.001;
        else
            time = 0.001;
    
        
        delayTimer2 = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(timer2FireMethod:) userInfo:nil repeats:NO];
        
    }

    
}

- (void)timer1FireMethod:(NSTimer *)timer {
    [self sendNewValues];
}

- (void)timer2FireMethod:(NSTimer *)timer {
    
    if ( delayTimer2 != nil ) {
        [delayTimer2 invalidate];
        delayTimer2 = nil;
    }
    
    [self showValuesWithDelay];
}

- (void)updateFooterView {
    
    if ( self.cbPicker.colorBrightnessWheelVisible ) {
        
        self.labelColorHEX.hidden = NO;
        self.labelColor.hidden = NO;
        self.vLine3.hidden = NO;
        self.cintLine3Top.constant = 5;
        self.cintFooterHeight.constant = 140;
        self.cintFooterTop.constant = 20;
        self.clPicker.hidden = NO;
        
    } else {
        
        self.labelColorHEX.hidden = YES;
        self.labelColor.hidden = YES;
        self.vLine3.hidden = YES;
        self.cintLine3Top.constant = -27;
        self.cintFooterHeight.constant = 108;
        self.cintFooterTop.constant = self.clPicker.frame.size.height*-1;
        self.clPicker.hidden = YES;
    }
    
}

- (void)setBWBrightnessWhellVisible:(BOOL)visible {
    
    self.cbPicker.bwBrightnessWheelVisible = visible;
    [self updateFooterView];
    
}

- (void)setColorBrightnessWheelVisible:(BOOL)visible {
    
    self.cbPicker.colorBrightnessWheelVisible = visible;
    [self updateFooterView];
}


-(void)updateView {
    
    [super updateView];
    
    if ( self.channelBase != nil ) {
        
        [self.labelCaption setText:[self.channelBase getChannelCaption]];
        
        switch(self.channelBase.func) {
                
            case SUPLA_CHANNELFNC_DIMMER:
            case SUPLA_CHANNELFNC_RGBLIGHTING:
            case SUPLA_CHANNELFNC_DIMMERANDRGBLIGHTING:
            
                _brightness = self.channelBase.brightnessValue;
                _colorBrightness = self.channelBase.colorBrightnessValue;
                _color = self.channelBase.colorValue;
                
                if ([self.channelBase isMemberOfClass:[SAChannelGroup class]]) {
                    SAChannelGroup *cgroup = (SAChannelGroup*)self.channelBase;

                    _colorMarkers = cgroup.colors;
                    _colorBrightnessMarkers = cgroup.colorBrightness;
                    _brightnessMarkers = cgroup.brightness;
                    
                }
            
                [self showValuesWithDelay];
            
                break;
        };
        

        
    }
    
    for(int a=1;a<self.clPicker.count;a++) {
        
        SAColorListItem *item = [[SAApp DB] getColorListItemForRemoteId:self.channelBase.remote_id andIndex:a forGroup:NO];
       
        if ( item == nil ) {
            [self.clPicker itemAtIndex:a setColor:[UIColor clearColor]];
            [self.clPicker itemAtIndex:a setPercent:0];
        } else {
            
            [self.clPicker itemAtIndex:a setColor:item.color == nil ? [UIColor clearColor] : (UIColor*)item.color];
            [self.clPicker itemAtIndex:a setPercent:[item.brightness floatValue]];
        }
    }
}


- (IBAction)segChanged:(id)sender {
    
    if ( self.segControl.hidden == NO ) {
        
        if ( self.segControl.selectedSegmentIndex ) {
            [self setBWBrightnessWhellVisible:YES];
        } else {
            [self setColorBrightnessWheelVisible:YES];
        }
        [self showValues];
    }

}

-(void)setChannelBase:(SAChannelBase *)channelBase {
    
    if ( self.channelBase == nil
         || ( channelBase != nil && self.channelBase.remote_id  != channelBase.remote_id ) ) {
        

        [self setBWBrightnessWhellVisible:NO];
        [self setColorBrightnessWheelVisible:NO];

        self.headerView.hidden = YES;
        self.cintPickerTop.constant = self.cintHeaderHeight.constant * -1;
        
        _moveEndTime = [NSDate dateWithTimeIntervalSince1970:0];
        _brightnessMarkers = nil;
        _colorBrightnessMarkers = nil;
        _colorMarkers = nil;
        
        if ( channelBase != nil ) {

            switch(channelBase.func) {
                case SUPLA_CHANNELFNC_DIMMER:
                    [self setBWBrightnessWhellVisible:YES];
                    break;
                case SUPLA_CHANNELFNC_RGBLIGHTING:
                    [self setColorBrightnessWheelVisible:YES];
                    break;
                case SUPLA_CHANNELFNC_DIMMERANDRGBLIGHTING:
                    [self setColorBrightnessWheelVisible:YES];
                    
                    self.segControl.selectedSegmentIndex = 0;
                    self.headerView.hidden = NO;
                    self.cintPickerTop.constant = 0;
                    
                    break;
            };
        }
        
    }

    [super setChannelBase:channelBase];
    
    if ( channelBase != nil && channelBase.isOnline == NO ) {
        [self.main_view detailShow:NO animated:NO];
    }
}

- (IBAction)stateBtnTouch:(id)sender {
    
    if ( self.channelBase == nil || self.channelBase.isOnline == NO )
        return;

    self.stateBtn.selected = !self.stateBtn.selected;
    int brightness = self.stateBtn.selected ? 100 : 0;
    
    if ( self.cbPicker.colorBrightnessWheelVisible ) {
        _colorBrightness = brightness;
    } else {
        _brightness = brightness;
    }
    [self showValues];
    [self sendNewValues];
    
}

-(void) cbPickerDataChanged {
   
    if ( self.cbPicker.colorBrightnessWheelVisible == YES ) {
        [self setColorLabel:self.cbPicker.color];
    }
    
    [self setBrightnessLabel:self.cbPicker.brightness];
    [self sendNewValues];
    
}

-(void) cbPickerMoveEnded {
    _moveEndTime = [NSDate date];
}

-(void)itemTouchedWithColor:(UIColor*)color andPercent:(float)percent {
    
    if ( self.cbPicker.colorBrightnessWheelVisible == NO
        || self.channelBase == nil
        || color == nil
        || [color isEqual: [UIColor clearColor]]) return;
    
    _colorBrightness = percent;
    _color = color;

    [self showValues];
    [self sendNewValues];

}

-(void)itemEditAtIndex:(int)index {
    
    if ( index <= 0 ) return;
    
    [self.clPicker itemAtIndex:index setColor:self.cbPicker.color];
    [self.clPicker itemAtIndex:index setPercent:self.cbPicker.brightness];
    
    SAColorListItem *item = [[SAApp DB] getColorListItemForRemoteId:self.channelBase.remote_id andIndex:index forGroup:NO];
    
    if ( item != nil ) {
        item.brightness = [NSNumber numberWithFloat:self.cbPicker.brightness];
        item.color = self.cbPicker.color;
        
        [[SAApp DB] updateColorListItem:item];
    }
}

@end
