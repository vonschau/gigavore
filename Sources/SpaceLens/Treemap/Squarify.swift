import Foundation

/// Squarified treemap layout (Bruls, Huizing, van Wijk).
/// Splits a rectangle into tiles proportional to the given values while
/// keeping tile aspect ratios close to a square. Values must be sorted
/// in descending order and positive.
enum Squarify {
    static func layout(values: [Double], in rect: CGRect) -> [CGRect] {
        guard !values.isEmpty else { return [] }
        let total = values.reduce(0, +)
        guard total > 0, rect.width > 1, rect.height > 1 else {
            return Array(repeating: .zero, count: values.count)
        }

        let scale = Double(rect.width * rect.height) / total
        let areas = values.map { $0 * scale }
        var result: [CGRect] = []
        result.reserveCapacity(values.count)
        var remaining = rect
        var index = 0

        while index < areas.count {
            let side = Double(min(remaining.width, remaining.height))
            guard side > 0 else {
                result.append(contentsOf: Array(repeating: .zero, count: areas.count - index))
                break
            }

            // Grow the row while the worst aspect ratio keeps improving.
            var rowEnd = index + 1
            var rowSum = areas[index]
            var worst = worstRatio(sum: rowSum, minArea: areas[index], maxArea: areas[index], side: side)
            while rowEnd < areas.count {
                let candidateSum = rowSum + areas[rowEnd]
                let candidateWorst = worstRatio(
                    sum: candidateSum,
                    minArea: areas[rowEnd],
                    maxArea: areas[index],
                    side: side
                )
                if candidateWorst > worst { break }
                rowSum = candidateSum
                worst = candidateWorst
                rowEnd += 1
            }

            // Lay the row along the shorter side of the remaining space.
            if remaining.width >= remaining.height {
                let rowWidth = CGFloat(rowSum) / remaining.height
                var y = remaining.minY
                for i in index..<rowEnd {
                    let h = rowWidth > 0 ? CGFloat(areas[i]) / rowWidth : 0
                    result.append(CGRect(x: remaining.minX, y: y, width: rowWidth, height: h))
                    y += h
                }
                remaining = CGRect(x: remaining.minX + rowWidth, y: remaining.minY,
                                   width: remaining.width - rowWidth, height: remaining.height)
            } else {
                let rowHeight = CGFloat(rowSum) / remaining.width
                var x = remaining.minX
                for i in index..<rowEnd {
                    let w = rowHeight > 0 ? CGFloat(areas[i]) / rowHeight : 0
                    result.append(CGRect(x: x, y: remaining.minY, width: w, height: rowHeight))
                    x += w
                }
                remaining = CGRect(x: remaining.minX, y: remaining.minY + rowHeight,
                                   width: remaining.width, height: remaining.height - rowHeight)
            }
            index = rowEnd
        }

        return result
    }

    /// Worst aspect ratio in a row of the given total area laid along `side`.
    private static func worstRatio(sum: Double, minArea: Double, maxArea: Double, side: Double) -> Double {
        let sideSq = side * side
        let sumSq = sum * sum
        guard sumSq > 0, minArea > 0 else { return .infinity }
        return max(sideSq * maxArea / sumSq, sumSq / (sideSq * minArea))
    }
}
