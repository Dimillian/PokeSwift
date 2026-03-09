import Foundation

private struct CLI {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            throw ExtractorError.invalidArguments("usage: PokeExtractCLI <extract|verify> --game red [--repo-root PATH] [--output-root PATH]")
        }

        var repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        var outputRoot = repoRoot.appendingPathComponent("Content", isDirectory: true)

        var index = 1
        while index < arguments.count {
            switch arguments[index] {
            case "--game":
                index += 2
            case "--repo-root":
                repoRoot = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
                index += 2
            case "--output-root":
                outputRoot = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
                index += 2
            default:
                throw ExtractorError.invalidArguments("unknown argument: \(arguments[index])")
            }
        }

        let configuration = RedContentExtractor.Configuration(repoRoot: repoRoot, outputRoot: outputRoot)
        switch command {
        case "extract":
            try RedContentExtractor.extract(configuration: configuration)
            print("extracted red content to \(outputRoot.path)")
        case "verify":
            try RedContentExtractor.verify(configuration: configuration)
            print("verified red content in \(outputRoot.path)")
        default:
            throw ExtractorError.invalidArguments("unknown command: \(command)")
        }
    }
}

do {
    try CLI.main()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
