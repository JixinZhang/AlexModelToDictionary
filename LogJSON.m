//
//  LogJSON.m
//  KingReader
//
//  Created by vvusu on 8/17/15.
//  Copyright (c) 2015 Shanghai Lianyou Network Technology Co., Ltd. All rights reserved.
//

#import "LogJSON.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, JSONModelDataType) {
    JSONModelDataTypeObject    = 0,
    JSONModelDataTypeBOOL      = 1,
    JSONModelDataTypeInteger   = 2,
    JSONModelDataTypeFloat     = 3,
    JSONModelDataTypeDouble    = 4,
    JSONModelDataTypeLong      = 5,
};

@implementation LogJSON
/*!
 * @brief 把对象（Model）转换成字典
 * @param model 模型对象
 * @return 返回字典
 */
+ (NSDictionary *)dictionaryWithModel:(id)model {
    if (model == nil) {
        return nil;
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    // 获取类名/根据类名获取类对象
    NSString *className = NSStringFromClass([model class]);
    id classObject = objc_getClass([className UTF8String]);
    
    // 获取所有属性
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(classObject, &count);
    
    // 遍历所有属性
    for (int i = 0; i < count; i++) {
        // 取得属性
        objc_property_t property = properties[i];
        // 取得属性名
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)
                                                          encoding:NSUTF8StringEncoding];
        // 取得属性值
        id propertyValue = nil;
        id valueObject = [model valueForKey:propertyName];
        
        if ([valueObject isKindOfClass:[NSDictionary class]]) {
            propertyValue = [NSDictionary dictionaryWithDictionary:valueObject];
        } else if ([valueObject isKindOfClass:[NSArray class]]) {
            propertyValue = [NSArray arrayWithArray:valueObject];
        } else {
            propertyValue = [NSString stringWithFormat:@"%@", [model valueForKey:propertyName]];
        }
        
        [dict setObject:propertyValue forKey:propertyName];
    }
    return [dict copy];
}

/*!
 * @brief 获取Model的所有属性名称
 * @param model 模型对象
 * @return 返回模型中的所有属性值
 */
+ (NSArray *)propertiesInModel:(id)model {
    if (model == nil) {
        return nil;
    }
    
    NSMutableArray *propertiesArray = [[NSMutableArray alloc] init];
    
    NSString *className = NSStringFromClass([model class]);
    id classObject = objc_getClass([className UTF8String]);
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(classObject, &count);
    
    for (int i = 0; i < count; i++) {
        // 取得属性名
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)
                                                          encoding:NSUTF8StringEncoding];
        [propertiesArray addObject:propertyName];
    }
    
    return [propertiesArray copy];
}

/*!
 * @brief 把字典转换成模型，模型类名为className
 * @param dict 字典对象
 * @param className 类名
 * @return 返回数据模型对象
 */
+ (id)modelWithDict:(NSDictionary *)dict className:(NSString *)className {
    if (dict == nil || className == nil || className.length == 0) {
        return nil;
    }
    
    id model = [[NSClassFromString(className) alloc]init];
    
    // 取得类对象
    id classObject = objc_getClass([className UTF8String]);
    
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(classObject, &count);
    Ivar *ivars = class_copyIvarList(classObject, nil);
    
    for (int i = 0; i < count; i ++) {
        // 取得成员名
        NSString *memberName = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
        const char *type = ivar_getTypeEncoding(ivars[i]);
        NSString *dataType =  [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        
        NSLog(@"Data %@ type: %@",memberName,dataType);
        
        JSONModelDataType rtype = JSONModelDataTypeObject;
        if ([dataType hasPrefix:@"c"]) {
            rtype = JSONModelDataTypeBOOL;// BOOL
        } else if ([dataType hasPrefix:@"i"]) {
            rtype = JSONModelDataTypeInteger;// int
        } else if ([dataType hasPrefix:@"f"]) {
            rtype = JSONModelDataTypeFloat;// float
        } else if ([dataType hasPrefix:@"d"]) {
            rtype = JSONModelDataTypeDouble; // double
        } else if ([dataType hasPrefix:@"l"])  {
            rtype = JSONModelDataTypeLong;// long
        }
        
        for (int j = 0; j < count; j++) {
            objc_property_t property = properties[j];
            NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)
                                                              encoding:NSUTF8StringEncoding];
            NSRange range = [memberName rangeOfString:propertyName];
            
            if (range.location == NSNotFound) {
                continue;
            } else {
                id propertyValue = [dict objectForKey:propertyName];
                
                switch (rtype) {
                    case JSONModelDataTypeBOOL: {
                        BOOL temp = [[NSString stringWithFormat:@"%@", propertyValue] boolValue];
                        propertyValue = [NSNumber numberWithBool:temp];
                    }
                        break;
                    case JSONModelDataTypeInteger: {
                        int temp = [[NSString stringWithFormat:@"%@", propertyValue] intValue];
                        propertyValue = [NSNumber numberWithInt:temp];
                    }
                        break;
                    case JSONModelDataTypeFloat: {
                        float temp = [[NSString stringWithFormat:@"%@", propertyValue] floatValue];
                        propertyValue = [NSNumber numberWithFloat:temp];
                    }
                        break;
                    case JSONModelDataTypeDouble: {
                        double temp = [[NSString stringWithFormat:@"%@", propertyValue] doubleValue];
                        propertyValue = [NSNumber numberWithDouble:temp];
                    }
                        break;
                    case JSONModelDataTypeLong: {
                        long long temp = [[NSString stringWithFormat:@"%@",propertyValue] longLongValue];
                        propertyValue = [NSNumber numberWithLongLong:temp];
                    }
                        break;
                        
                    default:
                        break;
                }
                [model setValue:propertyValue forKey:memberName];
                break;
            }
        }
    }
    return model;
}

@end