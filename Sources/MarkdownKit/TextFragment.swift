//
//  TextFragment.swift
//  MarkdownKit
//
//  Created by Matthias Zenger on 14/07/2019.
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
/// In MarkdownKit, text with markup is represented as a sequence of `TextFragment` objects.
/// Each `TextFragment` enumeration variant represents one form of inline markup. Since
/// markup can be arbitrarily nested, this is a recursive data structure (via struct `Text`).
///
public enum TextFragment: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
  case text(Substring, Substring)
  case code(Substring)
  case emph(Text)
  case strong(Text)
  case link(Text, String?, String?)
  case autolink(AutolinkType, Substring)
  case image(Text, String?, String?)
  case html(Substring)
  case delimiter(Character, Int, DelimiterRunType)
  case softLineBreak
  case hardLineBreak
  case escape
  case whiteSpace(Substring)

  /// Returns a description of this `TextFragment` object as a string as if the text would be
  /// represented in Markdown.
  public var description: String {
    switch self {
      case .text(let str, _):
        return str.description
      case .code(let str):
        return "`\(str.description)`"
      case .emph(let text):
        return "*\(text.description)*"
      case .strong(let text):
        return "**\(text.description)**"
      case .link(let text, let uri, let title):
        return "[\(text.description)](\(uri?.description ?? "") \(title?.description ?? ""))"
      case .autolink(_, let uri):
        return "<\(uri.description)>"
      case .image(let text, let uri, let title):
        return "![\(text.description)](\(uri?.description ?? "") \(title?.description ?? ""))"
      case .html(let tag):
        return "<\(tag.description)>"
      case .delimiter(let ch, let n, let type):
        var res = String(ch)
        for _ in 1..<n {
          res.append(ch)
        }
        return type.contains(.image) ? "!" + res : res
      case .softLineBreak:
        return "\n"
      case .hardLineBreak:
        return "\n"
      case .escape:
        return ""
      case .whiteSpace(let str):
        return str.description
    }
  }

  /// Returns a raw description of this `TextFragment` object as a string, i.e. as if the text
  /// fragment would be represented in Markdown but ignoring all markup.
  public var rawDescription: String {
    switch self {
      case .text(let str, _):
        return str.description
      case .code(let str):
        return str.description
      case .emph(let text):
        return text.rawDescription
      case .strong(let text):
        return text.rawDescription
      case .link(let text, _, _):
        return text.rawDescription
      case .autolink(_, let uri):
        return uri.description
      case .image(let text, _, _):
        return text.rawDescription
      case .html(let tag):
        return "<\(tag.description)>"
      case .delimiter(let ch, let n, let type):
        var res = String(ch)
        for _ in 1..<n {
          res.append(ch)
        }
        return type.contains(.image) ? "!" + res : res
      case .softLineBreak:
        return " "
      case .hardLineBreak:
        return " "
      case .escape:
        return ""
      case .whiteSpace(let text):
        return text.description
    }
  }

  public var rawString: String {
    switch self {
      case .text(let str, let space):
        return space.description + str.description
      case .code(let str):
          return "`\(str.description.trimmingCharacters(in: .whitespaces))`"
      case .emph(let text):
        return "*\(text.rawString)*"
      case .strong(let text):
        return "**\(text.rawString)**"
      case .link(let text, let url, _):
          return "[\(text.rawString)](\(url ?? ""))"
      case .autolink(_, let uri):
        return uri.description
      case .image(let text, let url, let title):
          return "\(text.rawString): ![alt text](\(url ?? "") \"\(title ?? "")\")"
      case .html(let tag):
        return "<\(tag.description)>"
      case .delimiter(let ch, let n, let type):
        var res = String(ch)
          for _ in 1..<n {
            res.append(ch)
          }
          return type.contains(.image) ? "!" + res : res
      case .softLineBreak:
        return "\n"
      case .hardLineBreak:
        return "\n"
      case .escape:
        return "\\"
      case .whiteSpace(_):
        return self.whiteSpaceToCode(fragment: self)
    }
  }

  /// Returns a debug description of this `TextFragment` object.
  public var debugDescription: String {
    switch self {
      case .text(let str, let space):
        return "text(\(str.debugDescription), " +
               "\(space.debugDescription))"
      case .code(let str):
        return "code(\(str.debugDescription))"
      case .emph(let text):
        return "emph(\(text.debugDescription))"
      case .strong(let text):
        return "strong(\(text.debugDescription))"
      case .link(let text, let uri, let title):
        return "link(\(text.debugDescription), " +
               "\(uri?.debugDescription ?? "nil"), \(title?.debugDescription ?? "nil"))"
      case .autolink(let type, let uri):
        return "autolink(\(type.debugDescription), \(uri.debugDescription))"
      case .image(let text, let uri, let title):
        return "image(\(text.debugDescription), " +
               "\(uri?.debugDescription ?? "nil"), \(title?.debugDescription ?? "nil"))"
      case .html(let tag):
        return "html(\(tag.debugDescription))"
      case .delimiter(let ch, let n, let runType):
        return "delimiter(\(ch.debugDescription), \(n), \(runType))"
      case .softLineBreak:
        return "softLineBreak"
      case .hardLineBreak:
        return "hardLineBreak"
      case .escape:
        return "escape"
      case .whiteSpace(_):
        return "whiteSpace(\(self.whiteSpaceToCode(fragment: self)))"
    }
  }

  public func whiteSpaceToCode(fragment: TextFragment) -> String {
    switch fragment {
      case .whiteSpace(let fragment):
        switch fragment {
          case "\u{0020}":
            return "&nbsp;"
          case "\u{2002}":
            return "&ensp;"
          case "\u{2003}":
            return "&emsp;"
          case "\u{2009}":
            return "&thinsp;"
          default:
            return ""
        }
      default:
        return ""
    }
  }
}

///
/// Represents an autolink type.
///
public enum AutolinkType: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
  case uri
  case email

  public var description: String {
    switch self {
    case .uri:
      return "uri"
    case .email:
      return "email"
    }
  }

  public var debugDescription: String {
    return self.description
  }
}

///
/// Lines are arrays of substrings.
///
public typealias Lines = ContiguousArray<Substring>

///
/// Each delimiter run is classified into a set of types which are represented via the
/// `DelimiterRunType` struct.
public struct DelimiterRunType: OptionSet, CustomStringConvertible {
  public let rawValue: UInt8

  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }

  public static let leftFlanking = DelimiterRunType(rawValue: 1 << 0)
  public static let rightFlanking = DelimiterRunType(rawValue: 1 << 1)
  public static let leftPunctuation = DelimiterRunType(rawValue: 1 << 2)
  public static let rightPunctuation = DelimiterRunType(rawValue: 1 << 3)
  public static let escaped = DelimiterRunType(rawValue: 1 << 4)
  public static let image = DelimiterRunType(rawValue: 1 << 5)

  public var description: String {
    var res = ""
    if self.rawValue & 0x1 == 0x1 {
      res = "\(res)\(res.isEmpty ? "" : ", ")leftFlanking"
    }
    if self.rawValue & 0x2 == 0x2 {
      res = "\(res)\(res.isEmpty ? "" : ", ")rightFlanking"
    }
    if self.rawValue & 0x4 == 0x4 {
      res = "\(res)\(res.isEmpty ? "" : ", ")leftPunctuation"
    }
    if self.rawValue & 0x8 == 0x8 {
      res = "\(res)\(res.isEmpty ? "" : ", ")rightPunctuation"
    }
    if self.rawValue & 0x10 == 0x10 {
      res = "\(res)\(res.isEmpty ? "" : ", ")escaped"
    }
    if self.rawValue & 0x20 == 0x20 {
      res = "\(res)\(res.isEmpty ? "" : ", ")image"
    }
    return "[\(res)]"
  }
}
