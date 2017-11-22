//
//  BlogsFeedReactor.swift
//  AwesomeBlogs
//
//  Created by wade.hawk on 2017. 7. 25..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import ReactorKit
import GameplayKit

class BlogsFeedReactor: Reactor {
    
    enum Action {
        case load(group: AwesomeBlogs.Group)
        case refresh(group: AwesomeBlogs.Group, force: Bool)
        case silentRefresh
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setEntries([Entry])
        case setAskingRefresh(Bool)
    }
    
    struct State {
        enum EventType {
            case load
            case setModel
        }
        var eventType: EventType = .load
        var isLoading: Bool = false
        var askingRefresh: Bool = false
        var entries: [Entry] = [Entry]()
        var viewModels: [BlogFeedCellViewModel] = [BlogFeedCellViewModel]()
    }
    
    deinit {
        log.verbose("deinit BlogFeedReactor")
    }

    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        let start = Observable.just(Mutation.setLoading(true))
        let end = Observable.just(Mutation.setLoading(false))
        switch action {
        case .load(let group):
            let getFeed = Api.getFeeds(group: group).map(Mutation.setEntries).asObservable()
            return Observable.concat(start,getFeed,end)
        case .refresh(let group,let force):
            let getFeed = Api.getFeeds(group: group, force: force).asObservable().map(Mutation.setEntries)
            return Observable.concat(start,getFeed,end)
        case .silentRefresh:
            let silentAsk = Observable.just(Mutation.setAskingRefresh(true))
            let silentTimeout = Observable.just(Mutation.setAskingRefresh(false)).delay(3, scheduler: SerialDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
            return Observable.concat(silentAsk,silentTimeout)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setLoading(isLoading):
            state.askingRefresh = false
            state.eventType = .load
            state.isLoading = isLoading
            return state
        case let .setEntries(entries):
            if state.entries.count == 0 || state.entries.first != entries.first {
                state.entries = entries
                state.eventType = .setModel
                state.viewModels = flatMapFeedViewModel(entries: entries)
            }
            return state
        case let .setAskingRefresh(askingRefresh):
            state.askingRefresh = askingRefresh
            return state
        }
    }
}

// MARK: - Service Logic
extension BlogsFeedReactor {
    func transform(mutation: Observable<BlogsFeedReactor.Mutation>) -> Observable<BlogsFeedReactor.Mutation> {
        return mutation
    }
    func flatMapFeedViewModel(entries: [Entry]) -> [BlogFeedCellViewModel] {
        var viewModels = [BlogFeedCellViewModel]()
        var mutableEntries = entries
        repeat {
            let randomBound = viewModels.count < 5 ? 3: 4
            let type = GKRandomSource.sharedRandom().nextInt(upperBound: randomBound)
            //type = viewModels.count == 0 ? 0 : type //facebook view test 를 한다면 이곳을 활성화 하자.
            switch type {
            case 1 where mutableEntries.count > 2:
                let entries = Array(mutableEntries.prefix(2))
                guard entries.count == 2 else { break }
                viewModels.append(BlogFeedCellViewModel(style: .diagonal, entries: entries))
                mutableEntries.removeFirst(2)
            case 2:
                guard let entry = mutableEntries.first else { break }
                viewModels.append(BlogFeedCellViewModel(style: .rectangle, entries: [entry]))
                mutableEntries.removeFirst()
            case 3:
                let entries = Array(mutableEntries.prefix(4))
                guard entries.count == 4 else { break }
                viewModels.append(BlogFeedCellViewModel(style: .table, entries: entries))
                mutableEntries.removeFirst(4)
            default:
                guard let entry = mutableEntries.first else { break }
                viewModels.append(BlogFeedCellViewModel(style: .circle, entries: [entry]))
                mutableEntries.removeFirst()
            }
        }while(mutableEntries.count > 0)
        return viewModels
    }
}
