/**
 * 仅给IOS 用MOV格式视频转换城MP4
 *
 * RNiosmp4.setMovPath().then((resolve) => { }).catch((error) => { });
 */

'use strict';

import {NativeModules, Platform} from 'react-native'
const NativeRNiosmp4 = NativeModules.RNiosmp4;


export default class RNiosmp4 {
  static setMovPath = (movPath,isCompress) => {
    if(Platform.OS === 'android') {
      return;
    }
    return NativeRNiosmp4.setMovPath(movPath,isCompress);
  }
}