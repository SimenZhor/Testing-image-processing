//
//  LinkedList.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 09/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import Foundation

public class LinkedList<T> {
    public typealias Node = LinkedListNode<T>
    
    fileprivate var head: Node?
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: Node? {
        return head
    }
    
    public var last: Node? {
        if var node = head {
            while case let next? = node.next {
                node = next
            }
            return node
        } else {
            return nil
        }
    }
    
    public var count: Int {
        if var node = head {
            var c = 1
            while case let next? = node.next {
                node = next
                c += 1
            }
            return c
        } else {
            return 0
        }
    }
    
    public func node(atIndex index: Int) -> Node? {
        if index >= 0 {
            var node = head
            var i = index
            while node != nil {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }
    
    public subscript(index: Int) -> T {
        let node = self.node(atIndex: index)
        assert(node != nil)
        return node!.value
    }
    
    public func append(_ value: T) {
        let newNode = Node(value: value)
        if let lastNode = last {
            newNode.previous = lastNode
            lastNode.next = newNode
        } else {
            head = newNode
        }
    }
    
    
    public func swapNodes(index: Int, index2: Int) -> Bool{
        if index < count && index2 < count{
            let node1 = self.node(atIndex: index)!
            let node2 = self.node(atIndex: index2)!
            /*let node2next = node2.next
            let node2prev = node2.previous
            
            node2.next = node1.next
            node2.previous = node1.previous
            
            node1.next = node2next
            node1.previous = node2prev*/
            swap(&node1.next, &node2.next)
            swap(&node1.previous, &node2.previous)
            return true
        }else{
            print("index out of bounds, nodes not swapped")
            print("Count: \(count), index: \(index), index2: \(index2)")
            return false
        }
        
    }
    
    public func moveNodeUp(index: Int){
        let count = self.count
        if index+1 < count && index >= 0{
            _ = swapNodes(index: index, index2: index+1)
        }else if index+1 == count{
            print("node already at tail")
        }else{
            print("index out of bounds, node does not exist")
        }
        
    }
    
    public func moveNodeDown(index: Int){
        let count = self.count
        if index < count && index >= 0{
            _ = swapNodes(index: index, index2: index-1)
        }else if index == 0{
            print("node already at head")
        }else{
            print("index out of bounds, node does not exist")
        }
    }
    
    
    private func nodesBeforeAndAfter(index: Int) -> (Node?, Node?) {
        assert(index >= 0)
        
        var i = index
        var next = head
        var prev: Node?
        
        while next != nil && i > 0 {
            i -= 1
            prev = next
            next = next!.next
        }
        assert(i == 0)  // if > 0, then specified index was too large
        return (prev, next)
    }
    
    public func insert(_ value: T, atIndex index: Int) {
        let (prev, next) = nodesBeforeAndAfter(index: index)
        
        let newNode = Node(value: value)
        newNode.previous = prev
        newNode.next = next
        prev?.next = newNode
        next?.previous = newNode
        
        if prev == nil {
            head = newNode
        }
    }
    
    public func removeAll() {
        head = nil
    }
    
    public func remove(node: Node) -> T {
        let prev = node.previous
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev
        
        node.previous = nil
        node.next = nil
        return node.value
    }
    
    public func remove(atIndex: Int) -> T{
        return remove(node:self.node(atIndex: atIndex)!)
    }
    
    public func removeLast() -> T {
        assert(!isEmpty)
        return remove(node: last!)
    }

    
}
extension LinkedList: CustomStringConvertible {
    public var description: String {
        var s = "["
        var node = head
        while node != nil {
            s += "\(node!.value)"
            node = node!.next
            if node != nil { s += ", " }
        }
        return s + "]"
    }
}

extension LinkedList {
    public func reverse() {
        var node = head
        while let currentNode = node {
            node = currentNode.next
            swap(&currentNode.next, &currentNode.previous)
            head = currentNode
        }
    }
}
extension LinkedList {
    public func map<U>(transform: (T) -> U) -> LinkedList<U> {
        let result = LinkedList<U>()
        var node = head
        while node != nil {
            result.append(transform(node!.value))
            node = node!.next
        }
        return result
    }
    
    public func filter(predicate: (T) -> Bool) -> LinkedList<T> {
        let result = LinkedList<T>()
        var node = head
        while node != nil {
            if predicate(node!.value) {
                result.append(node!.value)
            }
            node = node!.next
        }
        return result
    }
}

extension LinkedList {
    convenience init(array: Array<T>) {
        self.init()
        
        for element in array {
            self.append(element)
        }
    }
}
public class LinkedListNode<T> {
    var value: T
    var next: LinkedListNode?
    weak var previous: LinkedListNode?
    
    public init(value: T) {
        self.value = value
    }
}
