//
//  PlaneDetector.h
//  Ruler
//
//  Created by Tbxark on 18/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface PlaneDetector : NSObject

+ (SCNVector4)detectPlaneWithPoints:(NSArray <NSValue* >*)points;


@end
