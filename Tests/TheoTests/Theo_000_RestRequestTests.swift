import Foundation
import XCTest
@testable import Theo

#if os(Linux)
    import Dispatch
#endif


let TheoTimeoutInterval: TimeInterval = 10
var TheoNodeID: String                  = "100"
var TheoNodeIDForRelationship: String   = "101"
var TheoNodeIDForUser: String           = "102"
let TheoNodePropertyName: String        = "title"

class ConfigLoader: NSObject {

    class func loadRestConfig() -> RestConfig {

        let testPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().path

        let filePath = "\(testPath)/TheoRestConfig.json"

        return RestConfig(pathToFile: filePath)
    }

    class func loadBoltConfig() -> BoltConfig {

        let testPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().path

        let filePath = "\(testPath)/TheoBoltConfig.json"

        return BoltConfig(pathToFile: filePath)
    }

}





class Theo_000_RestRequestTests: XCTestCase {

    let configuration: RestConfig = ConfigLoader.loadRestConfig()


    override func setUp() {
        super.setUp()

        continueAfterFailure = false
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_000_successfullyFetchDBMeta() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_000_successfullyFetchDBMeta")

        theo.metaDescription({(meta, error) in

          XCTAssertNotNil(meta, "Meta can't be nil")
          XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

          exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_000_createTestData() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_000_createTestData")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        // Data

        let title = "Example"
        var postNode = Node()
        postNode.setProp("title", propertyValue: title)
        postNode.setProp("contentId", propertyValue: NSUUID().uuidString)
        postNode.setProp("tagstr", propertyValue: "a, b, c")
        postNode.setProp("timestamp", propertyValue: dateFormatter.string(from: Date()))
        postNode.setProp("url", propertyValue: "http://somewhere.out.there/post/1")

        let userUsername = "ajordan"
        var userNode = Node()
        userNode.setProp("username", propertyValue: userUsername as Any)

        let followingUsername = "hhansen"
        var followingNode = Node()
        followingNode.setProp("username", propertyValue: followingUsername as Any)

        // Create nodes

        let createDispatchGroup: DispatchGroup = DispatchGroup()

        createDispatchGroup.enter()
        theo.createNode(postNode) { (node, error) in
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let identifier = node?.stringId {
                TheoNodeID = identifier
            } else {
                XCTFail("Could not get newly created node identifier")
            }

            if let nodeTitle = node?.getProp("title") as? String {
                XCTAssertEqual(title, nodeTitle, "Title in should be title out")
            } else {
                XCTFail("Could not get newly created node property: title")
            }

            if let node = node {
                postNode = node
            }
            createDispatchGroup.leave()
        }

        createDispatchGroup.enter()
        theo.createNode(userNode) { (node, error) in
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let identifier = node?.stringId {
                TheoNodeIDForUser = identifier
            } else {
                XCTFail("Could not get newly created node identifier")
            }

            if let username = node?.getProp("username") as? String {
                XCTAssertEqual(userUsername, username, "Username in should be username out")
            } else {
                XCTFail("Could not get newly created node property: title")
            }

            if let node = node {
                userNode = node
            }
            createDispatchGroup.leave()
        }

        createDispatchGroup.enter()
        theo.createNode(followingNode) { (node, error) in
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let identifier = node?.stringId {
                TheoNodeIDForRelationship = identifier
            } else {
                XCTFail("Could not get newly created node identifier")
            }

            if let username = node?.getProp("username") as? String {
                XCTAssertEqual(followingUsername, username, "Username in should be username out")
            } else {
                XCTFail("Could not get newly created node property: username")
            }

            if let node = node {
                followingNode = node
            }
            createDispatchGroup.leave()
        }

        // Wait for creation to make relationships

        createDispatchGroup.notify(queue: DispatchQueue.main) {

            // Data
            var followingRelationship = Relationship()
            followingRelationship.relate(userNode, toNode: followingNode, type: RelationshipType.FOLLOWS)
            followingRelationship.setProp("startTime", propertyValue: dateFormatter.string(from: Date()) as Any)

            var lastPostRelationship = Relationship()
            lastPostRelationship.relate(followingNode, toNode: postNode, type: RelationshipType.LASTPOST)
            lastPostRelationship.setProp("postTime", propertyValue: dateFormatter.string(from: Date()) as Any)

            var nextPostRelationship = Relationship()
            nextPostRelationship.relate(postNode, toNode: userNode, type: RelationshipType.NEXTPOST)
            nextPostRelationship.setProp("scheduledTime", propertyValue: dateFormatter.string(from: Date()) as Any)

            // Create relationships

            let relateDispatchGroup = DispatchGroup()

            relateDispatchGroup.enter()
            theo.createRelationship(followingRelationship, completionBlock: { (relationship, error) in

                XCTAssertNotNil(relationship, "Relationship data can't be nil")
                XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

                relateDispatchGroup.leave()
            })

            relateDispatchGroup.enter()
            theo.createRelationship(lastPostRelationship, completionBlock: { (relationship, error) in

                XCTAssertNotNil(relationship, "Relationship data can't be nil")
                XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

                relateDispatchGroup.leave()
            })

            relateDispatchGroup.enter()
            theo.createRelationship(nextPostRelationship, completionBlock: { (relationship, error) in

                XCTAssertNotNil(relationship, "Relationship data can't be nil")
                XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

                relateDispatchGroup.leave()
            })

            relateDispatchGroup.notify(queue: DispatchQueue.main) {

                exp.fulfill()
            }
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_001_successfullyFetchNode() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_002_successfullyFetchNode")

        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_002_successfullyAccessProperty() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_002_successfullyAccessProperty")

        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {
                let nodePropertyValue = nodeObject.getProp(TheoNodePropertyName)

                XCTAssertNotNil(nodePropertyValue, "The nodeProperty can't be nil")

                exp.fulfill()
            }
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_003_successfullyHandleNonExistantAccessProperty() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_003_successfullyHandleNonExistantAccessProperty")
        let randomString: String = NSUUID().uuidString

        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {
                let nodePropertyValue = nodeObject.getProp(randomString)

                XCTAssertNil(nodePropertyValue, "The nodeProperty must be nil")

                exp.fulfill()
            }
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_004_successfullyAddNodeWithOutLabels() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_004_successfullyAddNodeWithOutLabels")
        var node = Node()
        let randomString: String = NSUUID().uuidString

        node.setProp("unitTestKey_1", propertyValue: ("unitTestValue_1" + randomString))
        node.setProp("unitTestKey_2", propertyValue: ("unitTestValue_2" + randomString))

        theo.createNode(node, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_005_successfullyAddRelationship() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_005_successfullyAddRelationship")

        /**
         * Setup dispatch group since you to make a 2 part transation
         */

        let fetchDispatchGroup: DispatchGroup = DispatchGroup()

        var parentNode: Node?
        var relatedNode: Node?
        var relationship: Relationship = Relationship()

        /**
         * Fetch the parent node
         */

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {
                parentNode = nodeObject
            }

            fetchDispatchGroup.leave()
        })

        /**
         * Fetch the related node
         */

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeIDForRelationship, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {
                relatedNode = nodeObject
            }

            fetchDispatchGroup.leave()
        })

        /**
         * End it
         */
//http://stackoverflow.com/questions/38552180/dispatch-group-cannot-notify-to-main-thread
        fetchDispatchGroup.notify(queue: DispatchQueue.main) {

            XCTAssertNotNil(parentNode, "parent node can't be nil")
            XCTAssertNotNil(relatedNode, "relatedNode node can't be nil")

            guard let parentNode = parentNode,
                let relatedNode = relatedNode else {
                    XCTFail("These nodes must have been defined")
                    return
            }

            relationship.relate(parentNode, toNode: relatedNode, type: RelationshipType.KNOWS)
            relationship.setProp("my_relationship_property_name", propertyValue: "my_relationship_property_value")

            theo.createRelationship(relationship, completionBlock: {(rel, error) in

                XCTAssertNotNil(rel, "Node data can't be nil")
                XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

                exp.fulfill()
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_006_succesfullyUpdateNodeWithProperties() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_006_succesfullyUpdateNodeWithProperties")

       /**
        * Setup dispatch group since you to make a 2 part transation
        */

        let fetchDispatchGroup: DispatchGroup = DispatchGroup()

        var updateNode: Node?

       /**
        * Fetch the parent node
        */

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {

                updateNode = nodeObject
            }

            fetchDispatchGroup.leave()
        })

       /**
        * End it
        */

        fetchDispatchGroup.notify(queue: DispatchQueue.main) {

            XCTAssertNotNil(updateNode, "updateNode node can't be nil")
            guard let updateNode = updateNode else {
                XCTFail("Node not defined, abort further testing")
                return
            }

            let updatedPropertiesDictionary: [String:Any] = ["test_update_property_label_1": "test_update_property_lable_2" as Any]

            theo.updateNode(updateNode, properties: updatedPropertiesDictionary,
                completionBlock: {(_, error) in

                    XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

                    exp.fulfill()
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_007_successfullyDeleteRelationship() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_007_successfullyDeleteRelationship")

        let fetchDispatchGroup = DispatchGroup()

        var relationshipIDToDelete: String?
        var nodeIDWithRelationships: String?

        /**
         * Fetch relationship for main RUD node
         */

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            nodeIDWithRelationships = node?.stringId
            XCTAssertNotNil(nodeIDWithRelationships, "nodeIDWithRelationships for relationships deletion can't be nil")

            fetchDispatchGroup.leave()
        })

        /**
         * Delete the relationship
         */

        fetchDispatchGroup.notify(queue: DispatchQueue.main) {

            guard let nodeIDWithRelationships = nodeIDWithRelationships else {
                XCTFail("Abort, nodeIDWithRelationships was nil")
                return
            }

            theo.fetchRelationshipsForNode(nodeIDWithRelationships, direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in

                XCTAssert(relationships.count >= 1, "Relationships must exist")
                XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")

                if let foundRelationship: Relationship = relationships[0] as Relationship! {

                    relationshipIDToDelete = "\(foundRelationship.id)"

                    XCTAssertNotNil(relationshipIDToDelete, "relationshipIDToDelete can't be nil")

                    theo.deleteRelationship(relationshipIDToDelete!, completionBlock: { error in

                        XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")

                        exp.fulfill()
                    })
                }
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_008_succesfullyAddNodeWithLabels() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_008_succesfullyAddNodeWithLabel")
        var node = Node()
        let randomString: String = NSUUID().uuidString

        node.setProp("succesfullyAddNodeWithLabel_1", propertyValue: "succesfullyAddNodeWithLabel_1" + randomString)
        node.setProp("succesfullyAddNodeWithLabel_2", propertyValue: "succesfullyAddNodeWithLabel_2" + randomString)
        node.setProp("succesfullyAddNodeWithLabel_3", propertyValue: 123456)

        let expectedLabel = "test_008_succesfullyAddNodeWithLabel_" + randomString
        node.addLabel(expectedLabel)

        theo.createNode(node, labels: node.labels, completionBlock: {(savedNode, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")
            XCTAssertNotNil(savedNode, "Node can't be nil")
            guard let savedNode = savedNode else {
                XCTFail("Assert fell through, abort")
                return
            }

            XCTAssertEqual(1, savedNode.labels.count, "Node has only one label")
            if let label = savedNode.labels.first {
                XCTAssertEqual(expectedLabel, label, "Labels must be the one which was set")
            } else {
                XCTFail("Could not get label")
            }

            // Then test cleanup
            theo.deleteNode(savedNode.stringId, completionBlock: { (deleteError) in
                XCTAssertNil(deleteError)
                exp.fulfill()
            })

        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_009_successfullyCommitTransaction() {

        let createStatement: String = "CREATE ( bike:Bike { weight: 10 } ) CREATE ( frontWheel:Wheel { spokes: 3 } ) CREATE ( backWheel:Wheel { spokes: 32 } ) CREATE p1 = bike -[:HAS { position: 1 } ]-> frontWheel CREATE p2 = bike -[:HAS { position: 2 } ]-> backWheel RETURN bike, p1, p2"
        let resultDataContents: Array<String> = ["REST"]
        let statement: Dictionary <String, Any> = ["statement": createStatement as Any, "resultDataContents": resultDataContents as Any]
        let statements: Array<Dictionary <String, Any>> = [statement]

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_010_successfullyCommitTransaction")

        theo.executeTransaction(statements, completionBlock: {(response, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")
            XCTAssertFalse(response.keys.isEmpty, "Response dictionary must not be empty \(response)")

            exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_011_succesfullyUpdateRelationshipWithProperties() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_011_succesfullyUpdateRelationshipWithProperties")

        let fetchDispatchGroup = DispatchGroup()

        var nodeIDWithRelationships: String?

        // Fetch relationship for main RUD node

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")

            if let nodeObject: Node = node {

                nodeIDWithRelationships = nodeObject.stringId

                XCTAssertNotNil(nodeIDWithRelationships, "nodeIDWithRelationships for relationships deletion can't be nil")
            }

            fetchDispatchGroup.leave()
        })

        // Delete the relationship

        fetchDispatchGroup.notify(queue: DispatchQueue.main) {

            guard let nodeIDWithRelationships = nodeIDWithRelationships else {
                XCTFail("nodeIDWithRelationships not defined")
                return
            }
            theo.fetchRelationshipsForNode(nodeIDWithRelationships, direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in

                XCTAssert(relationships.count >= 1, "Relationships must exist")
                XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")

                if let foundRelationship: Relationship = relationships.first {

                    let updatedProperties: Dictionary<String, Any> = ["updatedRelationshipProperty": "updatedRelationshipPropertyValue" as Any]

                    theo.updateRelationship(foundRelationship, properties: updatedProperties, completionBlock: {(_, error) in

                        XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")

                        exp.fulfill()
                    })

                } else {

                    XCTFail("no relationships where found")

                    exp.fulfill()
                }
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_012_successfullyExecuteCyperRequest() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_012_successfullyExecuteCyperRequest")
        let cyperQuery: String = "MATCH (u:User {username: {user} }) WITH u MATCH (u)-[:FOLLOWS*0..1]->(f) WITH DISTINCT f,u MATCH (f)-[:LASTPOST]-(lp)-[:NEXTPOST*0..3]-(p) RETURN p.contentId as contentId, p.title as title, p.tagstr as tagstr, p.timestamp as timestamp, p.url as url, f.username as username, f=u as owner"
        let cyperParams: Dictionary<String, Any> = ["user": "ajordan" as Any]

        theo.executeCypher(cyperQuery, params: cyperParams, completionBlock: {(cypher, error) in

            XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")
            XCTAssertNotNil(cypher, "Response can't be nil")

            exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_998_successfullyDeleteExistingNode() {

        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_999_successfullyDeleteExistingNode")

        var nodeIDForDeletion: String?
        var node = Node()
        let randomString: String = NSUUID().uuidString

        let createDispatchGroup = DispatchGroup()

        createDispatchGroup.enter()

        node.setProp("test_010_successfullyDeleteExistingNode_1", propertyValue: "test_010_successfullyDeleteExistingNode_1" + randomString)
        node.setProp("test_010_successfullyDeleteExistingNode_2", propertyValue: "test_010_successfullyDeleteExistingNode_2" + randomString)

        theo.createNode(node, completionBlock: {(savedNode, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description ?? "Error undefined")")
            XCTAssertNotNil(savedNode, "Saved node can't be nil")

            nodeIDForDeletion = savedNode?.stringId

            createDispatchGroup.leave()
        })

        createDispatchGroup.notify(queue: DispatchQueue.main) {

            XCTAssertNotNil(nodeIDForDeletion, "nodeIDForDeletion must NOT be nil")
            guard let nodeIDForDeletion = nodeIDForDeletion else {
                XCTFail("nodeIDForDeletion was not defined")
                return
            }

            theo.deleteNode(nodeIDForDeletion, completionBlock: { error in

                XCTAssertNil(error, "Error should be nil \(error?.description ?? "Error undefined")")

                exp.fulfill()
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func test_999_cleanupTests() {
        let theo: RestClient = RestClient(baseURL: configuration.host, user: configuration.username, pass: configuration.password)

        let exp = self.expectation(description: "cleanup")

        let nodeIds = [TheoNodeID, TheoNodeIDForRelationship, TheoNodeIDForUser]

        // First clean up the relationships
        let cleanupRelationshipsDispatchGroup: DispatchGroup = DispatchGroup()
        var doneIds = [String]()

        for nodeId in nodeIds {
            cleanupRelationshipsDispatchGroup.enter()
            theo.fetchRelationshipsForNode(nodeId, direction: nil, types: nil, completionBlock: { (relationships, error) in
                XCTAssertNil(error)
                DispatchQueue.main.async {
                    for relationship in relationships {
                        let relId = "\(relationship.id)"
                        if !doneIds.contains(relId) {
                            doneIds.append(relId)
                            cleanupRelationshipsDispatchGroup.enter()
                            theo.deleteRelationship(relId, completionBlock: { (error) in
                                XCTAssertNil(error)
                                DispatchQueue.main.async {
                                    cleanupRelationshipsDispatchGroup.leave()
                                }
                            })
                        }
                    }

                    cleanupRelationshipsDispatchGroup.leave()
                }
            })
        }

        // When relationships are done, clean up the nodes
        cleanupRelationshipsDispatchGroup.notify(queue: DispatchQueue.main) {

            let cleanupNodesDispatchGroup: DispatchGroup = DispatchGroup()

            let completionBlock = { (error: NSError?) in
                XCTAssertNil(error)
                cleanupNodesDispatchGroup.leave()
            }

            for nodeId in nodeIds {
                cleanupNodesDispatchGroup.enter()
                theo.deleteNode(nodeId, completionBlock: completionBlock)
            }

            cleanupNodesDispatchGroup.notify(queue: DispatchQueue.main) {
                exp.fulfill()
            }

        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }


    static var allTests = [
        ("test_000_successfullyFetchDBMeta", test_000_successfullyFetchDBMeta),
        ("test_000_createTestData", test_000_createTestData),
        ("test_001_successfullyFetchNode", test_001_successfullyFetchNode),
        ("test_002_successfullyAccessProperty", test_002_successfullyAccessProperty),
        ("test_003_successfullyHandleNonExistantAccessProperty", test_003_successfullyHandleNonExistantAccessProperty),
        ("test_004_successfullyAddNodeWithOutLabels", test_004_successfullyAddNodeWithOutLabels),
        ("test_005_successfullyAddRelationship", test_005_successfullyAddRelationship),
        ("test_006_succesfullyUpdateNodeWithProperties", test_006_succesfullyUpdateNodeWithProperties),
        ("test_007_successfullyDeleteRelationship", test_007_successfullyDeleteRelationship),
        ("test_008_succesfullyAddNodeWithLabels", test_008_succesfullyAddNodeWithLabels),
        ("test_009_successfullyCommitTransaction", test_009_successfullyCommitTransaction),
        ("test_011_succesfullyUpdateRelationshipWithProperties", test_011_succesfullyUpdateRelationshipWithProperties),
        ("test_012_successfullyExecuteCyperRequest", test_012_successfullyExecuteCyperRequest),
        ("test_998_successfullyDeleteExistingNode", test_998_successfullyDeleteExistingNode),
        ("test_999_cleanupTests", test_999_cleanupTests)
    ]
}

public struct RelationshipType {

    public static var KNOWS: String   = "KNOWS"
    public static var know: String    = "know"
    public static var FRIENDS: String = "FRIENDS"
    public static var likes: String   = "likes"
    public static var has: String     = "has"
    public static var knows: String   = "knows"
    public static var LOVES: String   = "LOVES"

    public static var FOLLOWS: String  = "FOLLOWS"
    public static var LASTPOST: String = "LASTPOST"
    public static var NEXTPOST: String = "NEXTPOST"
}

extension Node {
    public var stringId: String {
        get {
            return "\(id)"
        }
    }
}
