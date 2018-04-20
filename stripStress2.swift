//: dic helper
/// usage: `cat helper.swift | swift -`
/// Author: Antoine Cœur

import Cocoa
import Foundation

let origin = "cmudict.dict"
let destination = "cmudict-en-us.dict"

for argument in CommandLine.arguments {
    if argument.hasPrefix("origin=") {
        origin = apiBaseUrls[String(argument[(argument.index(argument.startIndex, offsetBy: 7))...])]!
    } else if argument.hasPrefix("destination=") {
        destination = apiBaseUrls[String(argument[(argument.index(argument.startIndex, offsetBy: 12))...])]!
    }
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

let stripStress: Void = {
    let acousticModelURL = URL(fileURLWithPath: self.acousticModelPath)
    let dictURL = acousticModelURL.appendingPathComponent("LanguageModelGeneratorLookupList.text", isDirectory: false)
    let content = try! String(contentsOf: dictURL, encoding: .utf8)
    let dict = MutableOrderedDictionary()
    let regexp = try! NSRegularExpression(pattern: "^([^ \\(]+)[^ ]* (.*)$", options: .anchorsMatchLines)
    regexp.enumerateMatches(in: content, options: [], range: NSRange(location: 0, length: content.count), using: { (result, _, _) in
        let match1 = String(content[Range(result!.range(at: 1), in: content)!])
        let match2 = String(content[Range(result!.range(at: 2), in: content)!]).filter { !"012".contains($0) }
        if let prunounciations = dict[match1] as? NSMutableOrderedSet {
            prunounciations.add(match2)
        } else {
            dict.setObject(NSMutableOrderedSet(object: match2), forKey: match1)
        }
    })
    var result = ""
    for (word, phonesList) in dict {
        let word = word as! String
        let phonesList = phonesList as! NSMutableOrderedSet
        for (i, phones) in phonesList.enumerated() {
            let phones = phones as! String
            result.append(word + (i == 0 ? "" : "(\(i + 1))") + " " + phones + "\n")
        }
    }
    try! result.write(to: dictURL, atomically: true, encoding: .utf8)
    print(dictURL)

    // `awk`
    //shell("awk", "", origin, ">", destination)
    // `python`
    //shell("python", "-c", "import shutil;shutil.make_archive('" + destination + "', 'zip', '.', 'resource')")
    /*
    shell("python", "-c", ""
        + "import io\n"
        + "import json\n"
        + "jsonPath = 'myJson.json'\n"
        + "with io.open(jsonPath, mode='r', encoding='utf8') as json_file:\n"
        + "    all_data = json.load(json_file)\n"
        + "with io.open(jsonPath, mode='w', encoding='utf8') as json_file:\n"
        + "    json_file.write(unicode(json.dumps(all_data, ensure_ascii=False, sort_keys=True, indent=2, separators=(',', ' : '))))\n"
    )
    */
}()
