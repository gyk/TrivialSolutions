/// Doubly-connected edge list (DCEL), or half-edge data structure
///
/// References
/// ----------
///
/// - https://en.wikipedia.org/wiki/Doubly_connected_edge_list
/// - https://www.students.cs.ubc.ca/~cs-424/tutorials/half-edge/

import Foundation

// NOTE: This implementation cannot handle edge cases (colinearity, butterfly vertices, etc.).

// FIXME: Make some fields public.

public class Vertex {
    /// One of half-edge emanating from this vertex. If the vertex is a boundary vertex, the `edge`
    /// must be a boundary edge.
    weak var edge: HalfEdge?

    let id: Int
    var x: Double
    var y: Double
    // 3D support can be trivially added. Indeed, half-edge data structure is more about topology.

    init(id: Int, x: Double, y: Double) {
        self.id = id
        self.x = x
        self.y = y
    }

    public func edgesAround() -> VertexEdgeSequence {
        return VertexEdgeSequence(around: self)
    }
}

public class HalfEdge: Equatable {
    var vertex: Vertex
    weak var face: Face?
    weak var next: HalfEdge? // should always be non-nil once set up
    weak var twin: HalfEdge? // should always be non-nil once set up

    // "Being able to simply assume that we have a non-null twin results in far fewer special
    // cases."

    public init(to vertex: Vertex) {
        self.vertex = vertex
    }

    public var fromTo: (Int, Int) {
        return (twin!.vertex.id, vertex.id)
    }

    // Conceptually, boundary half-edges belong to a "virtual" face.
    public var isBoundary: Bool {
        return face == nil
    }

    public static func ==(lhs: HalfEdge, rhs: HalfEdge) -> Bool {
        return lhs === rhs
    }
}

public class Face {
    unowned var edge: HalfEdge // FIXME: weak?

    public init(startFrom edge: HalfEdge) {
        self.edge = edge
    }
}

public class Mesh {
    var vertices: [Vertex]
    var faces: [Face]
    var edges: [HalfEdge]

    public init(vertices: [Vertex], faces: [Face], edges: [HalfEdge]) {
        self.vertices = vertices
        self.faces = faces
        self.edges = edges
    }

    public convenience init() {
        self.init(vertices: [], faces: [], edges: [])
    }

    public var numVertices: Int {
        return vertices.count
    }

    public var numFaces: Int {
        return faces.count
    }

    public func getVertex(at i: Int) -> Vertex? {
        guard 0 <= i && i < vertices.count else { return nil }
        return vertices[i]
    }

    public func getFace(at i: Int) -> Face? {
        guard 0 <= i && i < faces.count else { return nil }
        return faces[i]
    }

    public func getBoundaryVertices() -> AnySequence<Vertex> {
        var vidSet = Set<Int>()
        for edge in edges where edge.face == nil {
            vidSet.insert(edge.vertex.id)
        }
        return AnySequence(vidSet.map { vertices[$0] })
    }

    public func getBoundaryEdges() -> AnySequence<HalfEdge> {
        return AnySequence(edges.filter { $0.face == nil })
    }
}

// ===== Iterators =====

extension Face: Sequence {
    public func makeIterator() -> FaceEdgeIterator {
        return FaceEdgeIterator(self)
    }
}

/// Iterates through half-edges along the given face.
public class FaceEdgeIterator: IteratorProtocol {
    let face: Face
    var currEdge: HalfEdge?

    public init(_ face: Face) {
        self.face = face
    }

    public func next() -> HalfEdge? {
        if currEdge == nil {
            currEdge = face.edge
        } else if currEdge! == face.edge {
            return nil
        }

        defer { currEdge = currEdge?.next }
        return currEdge
    }
}

public class VertexEdgeSequence: Sequence {
    let vertex: Vertex

    public init(around vertex: Vertex) {
        self.vertex = vertex
    }

    public func makeIterator() -> VertexEdgeIterator {
        return VertexEdgeIterator(self.vertex)
    }
}

/// Iterates through half-edges around the given vertex.
public class VertexEdgeIterator: IteratorProtocol {
    let centerVertex: Vertex
    var currEdge: HalfEdge?

    public init(_ centerVertex: Vertex) {
        self.centerVertex = centerVertex
    }

    public func next() -> HalfEdge? {
        if currEdge == nil {
            currEdge = self.centerVertex.edge
        } else if currEdge!.fromTo == self.centerVertex.edge!.fromTo {
            return nil
        }

        defer {
            currEdge = currEdge!.twin!.next
        }
        return currEdge
    }
}

// ===== Populating =====

func getPairs<T, S: Sequence>(_ a: S) -> AnySequence<(T, T)> where S.Element == T {
    return AnySequence(zip(a, [AnySequence(a.dropFirst()), AnySequence(a.prefix(1))].joined()))
}

struct Pair: Hashable {
    let fst: Int
    let snd: Int
    init(_ uv: (Int, Int)) {
        (self.fst, self.snd) = uv
    }
}

/// Builds the mesh from polygon soup.
///
/// Precondition: Faces must be convex polygons.
public func buildMesh(
    vertexCoords: [(Double, Double)],
    faceVertices: inout [[Int]]
) -> Mesh {
    let vertices: [Vertex] = vertexCoords.enumerated().map { (i, coord) in
        let (x, y) = coord
        return Vertex(id: i, x: x, y: y)
    }

    var faces = [Face]()
    faces.reserveCapacity(faceVertices.count)
    var edgeDict = [Pair : HalfEdge]()
    edgeDict.reserveCapacity(faceVertices.map { $0.count }.reduce(0, +))

    for i in 0 ..< faceVertices.count {
        var vertexList = faceVertices[i]
        var face: Face?

        // Sorts vertices according to the angel relative to the centroid
        let (xSum, ySum) = vertexList
            .map { vertexCoords[$0] }
            .reduce((0.0, 0.0), { (sum, coord) in
                (sum.0 + coord.0, sum.1 + coord.1)
            })
        let inv = 1.0 / Double(vertexList.count)
        let (xC, yC) = (xSum * inv, ySum * inv)
        vertexList.sort(by: { (v1, v2) in
            let (x1, y1) = vertexCoords[v1]
            let (x2, y2) = vertexCoords[v2]
            return atan((y1 - yC) / (x1 - xC)) < atan((y2 - yC) / (x2 - xC))
        })

        for (u, v) in getPairs(vertexList) {
            var edge = edgeDict[Pair((u, v))]
            if edge == nil { // first time visiting this (full) edge
                edge = HalfEdge(to: vertices[v])
                let twinEdge = HalfEdge(to: vertices[u])

                edge!.twin = twinEdge
                twinEdge.twin = edge

                edgeDict[Pair((u, v))] = edge
                edgeDict[Pair((v, u))] = twinEdge
            }

            if face == nil {
                face = Face(startFrom: edge!)
            }

            if vertices[u].edge == nil {
                vertices[u].edge = edge
            }
        }
        faces.append(face!)

        for (uv1, uv2) in getPairs(getPairs(vertexList)) {
            let edge1 = edgeDict[Pair(uv1)]!
            let edge2 = edgeDict[Pair(uv2)]!
            edge1.next = edge2
            edge1.face = face!
        }
    }

    let mesh = Mesh(vertices: vertices, faces: faces, edges: Array(edgeDict.values))

    let boundaryEdges = Array(mesh.getBoundaryEdges())
    var outgoingEdgesDict = [Int : [HalfEdge]]() // vertex ID -> Half edge
    for be in boundaryEdges {
        let (fromV, _) = be.fromTo
        outgoingEdgesDict[fromV, default: []].append(be)
    }

    for (vid, outgoingEdges) in outgoingEdgesDict {
        mesh.vertices[vid].edge = outgoingEdges.first!
    }

    for be in boundaryEdges {
        var outgoingEdges = outgoingEdgesDict[be.vertex.id]!
        assert(!outgoingEdges.isEmpty)
        be.next = outgoingEdges.popLast()!
    }

    return mesh
}

// FIXME
public func smokeTest() {
    let vertexCoords = [
        (1.0, 4.0),
        (3.0, 4.0),
        (0.0, 2.0),
        (2.0, 2.0),
        (4.0, 2.0),
        (1.0, 0.0),
        (3.0, 0.0),
    ]
    var faceVertices = [
        [0, 2, 3],
        [0, 3, 1],
        [1, 3, 4],
        [2, 5, 3],
        [3, 5, 6],
        [3, 6, 4],
    ]

    let mesh = buildMesh(
        vertexCoords: vertexCoords,
        faceVertices: &faceVertices)

    for face in mesh.faces {
        print("Face ", terminator: "")
        for edge in face {
            print("\(edge.vertex.id) ", terminator: "")
        }
        print()
    }
    print()

    for v in mesh.vertices {
        print("Vertex #\(v.id)")
        for edge in v.edgesAround() {
            print("\tEdge \(edge.fromTo)")
        }
    }
}

smokeTest()
