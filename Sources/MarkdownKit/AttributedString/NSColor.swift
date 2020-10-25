//
//  NSColor.swift
//  MarkdownKit
//
//  Created by Matthias Zenger on 18/08/2019.
//  Copyright © 2019 Google LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

extension UIColor {

  public var hexString: String {
    guard let data = self.cgColor.components else {
      return "#FFFFFF"
    }

    var r, g, b: Int

    if self.cgColor.colorSpace?.model == CGColorSpaceModel.monochrome {
      r = Int(round(data[0] * 0xff))
      g = Int(round(data[0] * 0xff))
      b = Int(round(data[0] * 0xff))
    } else {
      r = Int(round(data[0] * 0xff))
      g = Int(round(data[1] * 0xff))
      b = Int(round(data[2] * 0xff))
    }

    return String(format: "#%02X%02X%02X", r, g, b)
  }

  open class var textColor: UIColor {
    return UIColor.darkText
  }
}
