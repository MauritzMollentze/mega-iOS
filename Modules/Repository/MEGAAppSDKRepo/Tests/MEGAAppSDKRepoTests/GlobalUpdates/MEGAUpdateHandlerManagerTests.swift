@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

struct MEGAUpdateHandlerManagerTests {
    @Test func test_whenMultipleSequencesCreated_shouldAddSdkDelegateOnce() async throws {
        // given
        let sdk = MockSdk()
        let sut = MEGAUpdateHandlerManager(sdk: sdk)
        let mockNode = MockNode(handle: 1)
        let nodeList = MockNodeList(nodes: [mockNode])
        
        let task1 = Task {
            var updatedNodes: [NodeEntity] = []
            for await nodes in sut.nodeUpdates {
                updatedNodes.append(contentsOf: nodes)
            }
            return updatedNodes
        }
        
        let task2 = Task {
            var updatedNodes: [NodeEntity] = []
            for await nodes in sut.nodeUpdates {
                updatedNodes.append(contentsOf: nodes)
            }
            return updatedNodes
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // when
        sdk.simulateOnNodesUpdate(nodeList)
        
        task1.cancel()
        task2.cancel()
        
        _ = await [task1.value, task2.value]
        
        // then
        #expect(sdk.addMEGADelegateCallCount == 1)
    }
    
    @Test func test_whenDifferentUpdatesCreated_shouldForwardUpdatesToAppropriateHandlers() async throws {
        // given
        let sdk = MockSdk()
        let sut = MEGAUpdateHandlerManager(sdk: sdk)
        let mockNode = MockNode(handle: 111)
        let mockUser = MockUser(handle: 999)
        let nodeList = MockNodeList(nodes: [mockNode])
        let userList = MockUserList(users: [mockUser])
        
        let task1 = Task {
            var updatedNodes: [NodeEntity] = []
            for await nodes in sut.nodeUpdates {
                updatedNodes.append(contentsOf: nodes)
            }
            return updatedNodes
        }
        
        let task2 = Task {
            var updatedUsers: [UserEntity] = []
            for await users in sut.userUpdates {
                updatedUsers.append(contentsOf: users)
            }
            return updatedUsers
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // when
        sdk.simulateOnNodesUpdate(nodeList)
        sdk.simulateOnUserUpdate(userList)
        
        task1.cancel()
        task2.cancel()
        
        let receivedNodes = await task1.value
        let receivedUsers = await task2.value
    
        // then
        #expect(receivedNodes.map(\.handle) == [111])
        #expect(receivedUsers.map(\.handle) == [999])
    }
    
    @Test func onSetAndSetElementsUpdate_forwardsToCorrectHandler() async throws {
        // given
        let sdk = MockSdk()
        let sut = MEGAUpdateHandlerManager(sdk: sdk)
        let megaSets = [MockMEGASet(handle: 65)]
        let megaSetElements = [MockMEGASetElement(handle: 54)]
        
        let setTask = Task {
            var updatedSets: [SetEntity] = []
            for await sets in sut.setsUpdates {
                updatedSets.append(contentsOf: sets)
            }
            return updatedSets
        }
        
        let setElements = Task {
            var updatedSetElementS: [SetElementEntity] = []
            for await setElements in sut.setElementsUpdates {
                updatedSetElementS.append(contentsOf: setElements)
            }
            return updatedSetElementS
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // when
        sdk.simulateOnSetUpdate(megaSets)
        sdk.simulateOnSetElementsUpdate(megaSetElements)
        
        setTask.cancel()
        setElements.cancel()
    
        // then
        #expect(await setTask.value == megaSets.toSetEntities())
        #expect(await setElements.value == megaSetElements.toSetElementsEntities())
    }
}
