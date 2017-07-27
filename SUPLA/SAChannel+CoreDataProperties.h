//
//  SAChannel+CoreDataProperties.h
//  SUPLA
//
//  Created by Przemysław Zygmunt on 02.11.2016.
//  Copyright © 2016 AC SOFTWARE SP. Z O.O. All rights reserved.
//

#import "SAChannel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface SAChannel (CoreDataProperties)

+ (NSFetchRequest<SAChannel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *caption;
@property (nullable, nonatomic, copy) NSNumber *channel_id;
@property (nullable, nonatomic, copy) NSNumber *func;
@property (nullable, nonatomic, copy) NSNumber *online;
@property (nullable, nonatomic, retain) NSObject *sub_value;
@property (nullable, nonatomic, retain) NSObject *value;
@property (nullable, nonatomic, copy) NSNumber *visible;
@property (nullable, nonatomic, retain) _SALocation *location;

@end

NS_ASSUME_NONNULL_END