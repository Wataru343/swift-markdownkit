//
//  DelimiterTransformer.swift
//  MarkdownKit
//
//  Created by Matthias Zenger on 09/06/2019.
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

///
/// An inline transformer which extracts delimiters into `delimiter` text fragments.
///
public final class DelimiterTransformer: InlineTransformer {

  public override func transform(_ fragment: TextFragment,
                                 from iterator: inout Text.Iterator,
                                 into res: inout Text) -> TextFragment? {
    guard case .text(let str) = fragment else {
      return super.transform(fragment, from: &iterator, into: &res)
    }
    var i = str.startIndex
    var start = i
    var escape = false
    var code = false
    var split = false
    while i < str.endIndex {
      switch str[i] {
        case "*", "_":
          if !escape && !code {
            var n = 1
            var j = str.index(after: i)
            while j < str.endIndex && str[j] == str[i] {
              j = str.index(after: j)
              n += 1
            }
            var delimiterRunType: DelimiterRunType = []
            // h: index of character preceding the delimiter run
            // i: index of character starting the delimiter run
            // j: index of character succeeding the delimiter run
            if start < i || (start == i && i > str.startIndex) {
              if start < i {
                res.append(fragment: .text(str[start..<i]))
              }
              let h = str.index(before: i)
              if j < str.endIndex &&
                 !isUnicodeWhitespace(str[j]) &&
                 (!isUnicodePunctuation(str[j]) ||
                  isUnicodeWhitespace(str[h]) ||
                  isUnicodePunctuation(str[h])) {
                delimiterRunType.formUnion(.leftFlanking)
                if isUnicodePunctuation(str[h]) {
                  delimiterRunType.formUnion(.leftPunctuation)
                }
                if isUnicodePunctuation(str[j]) {
                  delimiterRunType.formUnion(.rightPunctuation)
                }
              }
              if !isUnicodeWhitespace(str[h]) &&
                 (!isUnicodePunctuation(str[h]) ||
                  j >= str.endIndex ||
                  isUnicodeWhitespace(str[j]) ||
                  isUnicodePunctuation(str[j])) {
                delimiterRunType.formUnion(.rightFlanking)
                if isUnicodePunctuation(str[h]) {
                  delimiterRunType.formUnion(.leftPunctuation)
                }
                if j < str.endIndex && isUnicodePunctuation(str[j]) {
                  delimiterRunType.formUnion(.rightPunctuation)
                }
              }
            } else if j < str.endIndex && !isUnicodeWhitespace(str[j]) {
              delimiterRunType.formUnion(.leftFlanking)
            }
            res.append(fragment: .delimiter(str[i], n,delimiterRunType))
            split = true
            start = j
            i = j
          } else {
            i = str.index(after: i)
            escape = false
          }
        case "`":
          var n = 1
          var j = str.index(after: i)
          while j < str.endIndex && str[j] == "`" {
            j = str.index(after: j)
            n += 1
          }
          if start < i {
            res.append(fragment: .text(str[start..<i]))
          }
          res.append(fragment: .delimiter("`", n, escape ? .escaped : []))
          split = true
          start = j
          i = j
          escape = false
          code = !code
        case "<", ">", "[", "]", "(", ")", "\"", "'":
          if !escape && !code {
            if start < i {
              res.append(fragment: .text(str[start..<i]))
            }
            res.append(fragment: .delimiter(str[i], 1, []))
            split = true
            i = str.index(after: i)
            start = i
          } else {
            i = str.index(after: i)
            escape = false
          }
        case "!":
          let j = str.index(after: i)
          if !escape && !code && j < str.endIndex && str[j] == "[" {
            if start < i {
              res.append(fragment: .text(str[start..<i]))
            }
            res.append(fragment: .delimiter("[", 1, .image))
            split = true
            i = str.index(after: j)
            start = i
          } else {
            i = j
            escape = false
          }
        case "&": // white space
          guard !escape && !code else {
            i = str.index(after: i)
            escape = false
            break
          }

          if let j = str.index(i, offsetBy: 6, limitedBy: str.endIndex), str[i..<j] == "&nbsp;" {
            let s = str[start..<i]
            if s.count > 0 {
              res.append(fragment: .text(s))
            }
            res.append(fragment: .whiteSpace("\u{0020}"))
            i = j
            split = true
            start = i
          } else if let j = str.index(i, offsetBy: 6, limitedBy: str.endIndex), str[i..<j] == "&ensp;" {
            let s = str[start..<i]
            if s.count > 0 {
              res.append(fragment: .text(s))
            }
            res.append(fragment: .whiteSpace("\u{2002}"))
            i = j
            split = true
            start = i
          } else if let j = str.index(i, offsetBy: 6, limitedBy: str.endIndex), str[i..<j] == "&emsp;" {
            let s = str[start..<i]
            if s.count > 0 {
              res.append(fragment: .text(s))
            }
            res.append(fragment: .whiteSpace("\u{2003}"))
            i = j
            split = true
            start = i
          } else if let j = str.index(i, offsetBy: 8, limitedBy: str.endIndex), str[i..<j] == "&thinsp;" {
            let s = str[start..<i]
            if s.count > 0 {
              res.append(fragment: .text(s))
            }
            res.append(fragment: .whiteSpace("\u{2009}"))
            i = j
            split = true
            start = i
          } else {
            i = str.index(after: i)
            escape = false
          }
        case "\\":
          let s = str[start..<i]
          if s.count > 0 {
            res.append(fragment: .text(s))
          }

          i = str.index(after: i)
          if !code {
            escape = !escape
          }

          if escape {
            res.append(fragment: .escape)
          } else {
            res.append(fragment: .text("\\\\"))
          }
          split = true
          start = i
        default:
          i = str.index(after: i)
          escape = false
      }
    }
    if split {
      if start < str.endIndex {
        res.append(fragment: .text(str[start...]))
      }
    } else {
      res.append(fragment: fragment)
    }
    return iterator.next()
  }
}
