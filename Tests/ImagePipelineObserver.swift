// The MIT License (MIT)
//
// Copyright (c) 2015-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Nuke

final class ImagePipelineObserver: ImagePipelineDelegate, @unchecked Sendable {
    var startedTaskCount = 0
    var cancelledTaskCount = 0
    var completedTaskCount = 0

    static let didStartTask = Notification.Name("com.github.kean.Nuke.Tests.ImagePipelineObserver.DidStartTask")
    static let didCancelTask = Notification.Name("com.github.kean.Nuke.Tests.ImagePipelineObserver.DidCancelTask")
    static let didCompleteTask = Notification.Name("com.github.kean.Nuke.Tests.ImagePipelineObserver.DidFinishTask")

    static let taskKey = "taskKey"
    static let resultKey = "resultKey"

    var events = [ImageTaskEvent]()

    func imageTaskWillStart(_ task: ImageTask) {
        startedTaskCount += 1
        NotificationCenter.default.post(name: ImagePipelineObserver.didStartTask, object: self, userInfo: [ImagePipelineObserver.taskKey: task])
        events.append(.started)
    }

    func imageTaskDidCancel(_ task: ImageTask) {
        cancelledTaskCount += 1
        NotificationCenter.default.post(name: ImagePipelineObserver.didCancelTask, object: self, userInfo: [ImagePipelineObserver.taskKey: task])
        events.append(.cancelled)
    }

    func imageTask(_ task: ImageTask, didUpdateProgress progress: (completed: Int64, total: Int64)) {
        events.append(.progressUpdated(completedUnitCount: progress.completed, totalUnitCount: progress.total))
    }

    func imageTask(_ task: ImageTask, didProduceProgressiveResponse response: ImageResponse) {
        events.append(.intermediateResponseReceived(response: response))
    }

    func imageTask(_ task: ImageTask, didCompleteWithResult result: Result<ImageResponse, ImagePipeline.Error>) {
        completedTaskCount += 1
        NotificationCenter.default.post(name: ImagePipelineObserver.didCompleteTask, object: self, userInfo: [ImagePipelineObserver.taskKey: task, ImagePipelineObserver.resultKey: result])
        events.append(.completed(result: result))
    }
}

enum ImageTaskEvent: Equatable {
    case started
    case cancelled
    case intermediateResponseReceived(response: ImageResponse)
    case progressUpdated(completedUnitCount: Int64, totalUnitCount: Int64)
    case completed(result: Result<ImageResponse, ImagePipeline.Error>)

    static func == (lhs: ImageTaskEvent, rhs: ImageTaskEvent) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started): return true
        case (.cancelled, .cancelled): return true
        case let (.intermediateResponseReceived(lhs), .intermediateResponseReceived(rhs)): return lhs == rhs
        case let (.progressUpdated(lhsTotal, lhsCompleted), .progressUpdated(rhsTotal, rhsCompleted)):
            return (lhsTotal, lhsCompleted) == (rhsTotal, rhsCompleted)
        case let (.completed(lhs), .completed(rhs)): return lhs == rhs
        default: return false
        }
    }
}
