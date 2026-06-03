//
//  RingBuffer.swift
//  Basil
//
//  Created by Ian Brault on 4/4/26.
//

class RingBuffer<T: Codable>: Codable, Sequence {

    private var data: [T?]
    private var readPointer: Int
    private var writePointer: Int
    var count: Int

    var isEmpty: Bool {
        self.count == 0
    }
    var isFull: Bool {
        self.count == self.data.count
    }

    init(size: Int) {
        self.data = Array(repeating: nil, count: size)
        self.readPointer = 0
        self.writePointer = 0
        self.count = 0
    }

    func pushBack(_ item: T) {
        if self.isFull {
            // Buffer is full, cannot push
            // Drop silently
            return
        }
        self.data[self.writePointer] = item
        self.writePointer = (self.writePointer + 1) % self.data.count
        self.count += 1
    }

    func popFront() -> T? {
        if self.isEmpty {
            return nil
        }
        let item = self.data[self.readPointer]
        self.readPointer = (self.readPointer + 1) % self.data.count
        self.count -= 1
        return item
    }

    func removeAll() {
        self.data = Array(repeating: nil, count: self.data.count)
        self.readPointer = 0
        self.writePointer = 0
        self.count = 0
    }

    func makeIterator() -> RingBufferIterator<T> {
        return RingBufferIterator(self)
    }
}

struct RingBufferIterator<T: Codable>: IteratorProtocol {

    let ringBuffer: RingBuffer<T>

    init(_ ringBuffer: RingBuffer<T>) {
        self.ringBuffer = ringBuffer
    }

    mutating func next() -> T? {
        return self.ringBuffer.popFront()
    }
}
