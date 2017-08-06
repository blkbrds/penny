import HTTP
import Vapor
import Foundation
import MySQL
import TLS

let VERSION = "0.3.0"
let PENNY = "U6K4XJYPR"
let GENERAL = "C4NDAAEHF"

let configDirectory = workingDirectory + "Config/"

let config = try Config(
    prioritized: [
            .commandLine,
            .directory(root: configDirectory + "secrets"),
            .directory(root: configDirectory + "production")
    ]
)

// Config variables
guard let token = config["bot-config", "token"]?.string else { throw BotError.missingConfig }

guard let user = config["mysql", "user"]?.string, let pass = config["mysql", "pass"]?.string else { throw BotError.missingMySQLCredentials }

guard
    let host = config["mysql", "host"]?.string,
    let port = config["mysql", "port"]?.string
    else { throw BotError.missingMySQLDatabaseUrl }

guard let databaseName = config["mysql", "database"]?.string else { throw BotError.missingMySQLDatabaseName }

let mysql = try MySQL.Database(
    hostname: host,
    user: user,
    password: pass,
    database: databaseName
).makeConnection()

// WebSocket Init
let rtmResponse = try loadRealtimeApi(token: token)

guard let validChannels = rtmResponse.data["channels", "id"]?.array?.flatMap({ $0.string }) else { throw BotError.unableToLoadChannels }

guard let webSocketURL = rtmResponse.data["url"]?.string else { throw BotError.invalidResponse }

func credit(_ ws: WebSocket, _ user: String, channel: String, threadTs: String?, printError: Bool = true) throws {
    if true {
        var response: SlackMessage
        do {
            let total = try mysql.addCoins(for: user)
            response = SlackMessage(
                to: channel,
                text: "<@\(user)> has \(total) :coin:",
                threadTs: threadTs
            )
        } catch {
            response = SlackMessage(
                to: channel,
                text: "```\(error.localizedDescription)```",
                threadTs: threadTs
            )
        }
        try ws.send(response)
    }
}

try EngineClient.factory.socket.connect(to: webSocketURL) { ws in
    print("Connected.")

    ws.onText = { ws, text in
        let event = try JSON(bytes: text.utf8.array)
        let last3Seconds = NSDate().timeIntervalSince1970 - 3

        let threadTs = event["thread_ts"]?.string

        guard
            let channel = event["channel"]?.string,
            let message = event["text"]?.string,
            let fromId = event["user"]?.string,
            let ts = event["ts"].flatMap({ $0.string.flatMap({ Double($0) }) }),
            ts >= last3Seconds
            else { return }

        let trimmed = message.trimmedWhitespace()

        print("Message: \(trimmed)")

        if trimmed.hasPrefix("<@") && trimmed.hasCoinSuffix { // leads w/ user
            guard
                let toId = trimmed.components(separatedBy: "<@").last?.components(separatedBy: ">").first,
                toId != fromId,
                fromId != PENNY
                else { return }

//            if validChannels.contains(channel) {
            try credit(ws, toId, channel: channel, threadTs: threadTs)
//            } else {
//                let response = SlackMessage(
//                    to: channel,
//                    text: "Sorry, I only work in public channels. Try thanking in <#\(GENERAL)>",
//                    threadTs: threadTs
//                )
//                try ws.send(response)
//            }
        } else if trimmed.hasPrefix("<@\(PENNY)>") || trimmed.hasSuffix("<@\(PENNY)>") {
            if trimmed.lowercased().contains(any: "hello", "hey", "hiya", "hi", "aloha", "sup") {
                let response = SlackMessage(to: channel,
                                            text: "Hey <@\(fromId)> 👋",
                                            threadTs: threadTs)
                try ws.send(response)
            } else if trimmed.lowercased().contains("version") {
                let response = SlackMessage(to: channel,
                                            text: "Current version is \(VERSION)",
                                            threadTs: threadTs)
                try ws.send(response)
            } else if trimmed.lowercased().contains("environment") {
                let env = config["app", "env"]?.string ?? "debug"
                let response = SlackMessage(to: channel,
                                            text: "Current environment is \(env)",
                                            threadTs: threadTs)
                try ws.send(response)
            } else if trimmed.lowercased().contains("top") {
                let limit = trimmed.components(separatedBy: " ")
                    .last
                    .flatMap { Int($0) }
                    ?? 10
                let top = try mysql.top(limit: limit).map { "- <@\($0["user"]?.string ?? "?")>: \($0["coins"]?.int ?? 0)" } .joined(separator: "\n")
                let response = SlackMessage(to: channel,
                                            text: "Top \(limit): \n\(top)",
                                            threadTs: threadTs)
                try ws.send(response)
            } else if trimmed.lowercased().contains("how many coins") {
                let user = trimmed.components(separatedBy: " ")
                    .lazy
                    .filter({
                        $0.hasPrefix("<@")
                            && $0.hasSuffix(">")
                            && $0 != "<@\(PENNY)>"
                    })
                    .map({ $0.characters.dropFirst(2).dropLast() })
                    .first
                    .flatMap({ String($0) })
                    ?? fromId

                let count = try mysql.coinsCount(for: user)
                let response = SlackMessage(to: channel,
                                            text: "<@\(user)> has \(count) :coin:",
                                            threadTs: threadTs)
                try ws.send(response)
            }
        }
    }

    ws.onClose = { ws, _, _, _ in
        print("\nClosed.\n")
    }
}
