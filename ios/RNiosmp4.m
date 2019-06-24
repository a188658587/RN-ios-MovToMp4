#import "RNiosmp4.h"

@implementation RNiosmp4

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setMovPath:(NSString *)movPath
                  isCompress:(BOOL)isCompress
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL * movurl = [NSURL fileURLWithPath:movPath];
  NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
  [formater setDateFormat:@"YYYY-MM-dd-HH-mm-ss"];
  if(isCompress){
//  NSLog(@"进入转MP4");
//  NSLog(movPath);
  
  // NSLog(movurl);
  NSURL *newVideoUrl ; //一般.mp4
  newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/tmp/%@.mp4", [formater stringFromDate: [NSDate date]]]] ;
  //这个是保存在app自己的沙盒路径里，后面可以选择是否在上传后删除掉。我建议删除掉，免得占空间。
  // [picker dismissViewControllerAnimated:YES completion:nil];

  AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movurl options:nil];

  AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
  //  NSLog(resultPath);
  exportSession.outputURL = newVideoUrl;
  exportSession.outputFileType = AVFileTypeMPEG4;
  exportSession.shouldOptimizeForNetworkUse= YES;
  [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
    NSError * err=[NSError errorWithDomain:@"test" code:0 userInfo:nil];
    switch (exportSession.status) {
      case AVAssetExportSessionStatusCancelled:
        // reject(@"AVAssetExportSessionStatusCancelled");
        NSLog(@"AVAssetExportSessionStatusCancelled");
        reject(@"0",@"AVAssetExportSessionStatusCancelled",err);
        break;
      case AVAssetExportSessionStatusUnknown:
        // reject(@"AVAssetExportSessionStatusUnknown");
        NSLog(@"AVAssetExportSessionStatusUnknown");
        err=[NSError errorWithDomain:@"Error" code:1 userInfo:nil];
        reject(@"1",@"AVAssetExportSessionStatusUnknown",err);
        break;
      case AVAssetExportSessionStatusWaiting:
        // reject(@"AVAssetExportSessionStatusWaiting");
        NSLog(@"AVAssetExportSessionStatusWaiting");
        err=[NSError errorWithDomain:@"Error" code:2 userInfo:nil];
        reject(@"2",@"AVAssetExportSessionStatusWaiting",err);
        break;
      case AVAssetExportSessionStatusExporting:
        // reject(@"AVAssetExportSessionStatusExporting");
        NSLog(@"AVAssetExportSessionStatusExporting");
        err=[NSError errorWithDomain:@"Error" code:3 userInfo:nil];
        reject(@"3",@"AVAssetExportSessionStatusExporting",err);
        break;
      case AVAssetExportSessionStatusCompleted:
        NSLog(@"AVAssetExportSessionStatusCompleted");

        resolve(@{@"mpvset": @{
                      @"movPath": movPath,
                      @"Length":  [NSString stringWithFormat:@"%g",[self getVideoLength:movurl]],
                      @"size": [NSString stringWithFormat:@"%g",[self getFileSize:[movurl path]]],
                      },
                  @"mp4out": @{
                      @"movPath": [newVideoUrl path],
                      @"Length":  [NSString stringWithFormat:@"%g",[self getVideoLength:newVideoUrl]],
                      @"size": [NSString stringWithFormat:@"%g",[self getFileSize:[newVideoUrl path]]],
                      },
                  @"firstFrame": @{
                      @"movPath":[self savescanresultimage:[self getVideoPreViewImage:movurl ]
                                                    imagename:[NSHomeDirectory() stringByAppendingFormat:@"/tmp/%@.png", [formater stringFromDate: [NSDate date]]]],
                      },
                  });
        //UISaveVideoAtPathToSavedPhotosAlbum([outputURL path], self, nil, NULL);//这个是保存到手机相册
        break;
      case AVAssetExportSessionStatusFailed:
        NSLog(@"AVAssetExportSessionStatusFailed");
        err=[NSError errorWithDomain:@"Error" code:5 userInfo:nil];
        reject(@"5",@"AVAssetExportSessionStatusFailed",err);
        break;
    }
  }];
  }else{
    NSString * len =[NSString stringWithFormat:@"%g",[self getVideoLength:movurl]];
    NSString * size =[NSString stringWithFormat:@"%g",[self getFileSize:[movurl path]]];
    resolve(@{@"mpvset": @{
                  @"movPath": movPath,
                  @"Length":  len,
                  @"size": size,
                  },
              @"mp4out": @{
                  @"movPath": movPath,
                  @"Length":  len,
                  @"size": size,
                  },
              @"firstFrame": @{
                  @"movPath":[self savescanresultimage:[self getVideoPreViewImage:movurl ]
                                             imagename:[NSHomeDirectory() stringByAppendingFormat:@"/tmp/%@.png", [formater stringFromDate: [NSDate date]]]],
                  },
              });
    
  }
}




/*
 获取视频大小
 */
- (CGFloat) getFileSize:(NSString *)path
{
  NSLog(@"%@",path);
  NSFileManager *fileManager = [NSFileManager defaultManager];
  float filesize = -1.0;
  if ([fileManager fileExistsAtPath:path]) {
    NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
    unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
    filesize = 1.0*size/1024;
  }else{
    NSLog(@"找不到文件");
  }
  return filesize;
}

/*
 获取视频长短
 */
- (CGFloat) getVideoLength:(NSURL *)URL
{
  AVURLAsset *avUrl = [AVURLAsset assetWithURL:URL];
  CMTime time = [avUrl duration];
  int second = ceil(time.value/time.timescale);
  return second;
}

/*
 获取视频第一帧
 */
- (UIImage*) getVideoPreViewImage:(NSURL *)path
{
  AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
  AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
  assetGen.appliesPreferredTrackTransform = YES;
  CMTime time = CMTimeMakeWithSeconds(0, 1);
  NSError *error = nil;
  CMTime actualTime;
  CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
  UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
  CGImageRelease(image);
  return videoImage;
}

/*
 保存图片方法
 */
-(NSString *)savescanresultimage:(UIImage *)resultimage imagename:(NSString *)strimagename
{
  NSData *imageData = UIImagePNGRepresentation(resultimage);
//  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString *documentsDirectory = [paths objectAtIndex:0];
//  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:strimagename]; //Add the file name
  [imageData writeToFile:strimagename atomically:YES];
  return strimagename;
}

@end
