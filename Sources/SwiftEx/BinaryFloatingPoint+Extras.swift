//
//  BinaryFloatingPoint+Extras.swift
//  SwiftEx
//
//  Created by Ryan Robinson on 12/29/23.
//

import Foundation

// MARK: - Clamping + Mapping

public extension BinaryFloatingPoint {
    /// Clamp a float-type value to a given range.
    /// - Parameter range: The range on which to clamp.
    /// - Returns: A float-type value, clamped to the given range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
    /// Linearly map a float-type value from one range to another.
    /// - Parameters:
    ///   - srcRange: The source range of the value.
    ///   - dstRange: The destination range.
    /// - Returns: A float-type value on the destination range.
    func mapped(from srcRange: ClosedRange<Self>, to dstRange: ClosedRange<Self>) -> Self {
        return (self - srcRange.lowerBound) / srcRange.size * dstRange.size + dstRange.lowerBound
    }
    
    /// Denormalize a float-type value with variable taper.
    /// - Parameters:
    ///   - range: The destination range.
    ///   - taper: The taper amount. Must satisfy 0 < taper < 1. (0.5 is linear)
    ///   - aroundCenter: Whether to apply the taper symmetrically around the center of the target range.
    /// - Returns: A float-type value on the destination range.
    func denormalized(to range: ClosedRange<Self>, taper: Self = 0.5, aroundCenter: Bool = false) -> Self {
        if aroundCenter {
            if self >= 0.5 {
                let x = 2.0 * self - 1.0
                let warped = x.denormalized(to: range.upperHalfRange, taper: taper)
                return warped
            } else {
                let x = -2.0 * self + 1.0
                let warped = x.denormalized(to: 0...1, taper: taper)
                let reflected = -1.0 * warped + 1.0
                let mapped = reflected.denormalized(to: range.lowerHalfRange)
                return mapped
            }
        } else {
            return denormalized(to: range, taper: taper)
        }
    }
    
    /// Normalize a float-type value with variable taper.
    /// - Parameters:
    ///   - range: The source range.
    ///   - taper: The taper amount. Must satisfy 0 < taper < 1. (0.5 is linear)
    ///   - aroundCenter: Whether to apply the taper symmetrically around the center of the target range.
    /// - Returns: A float-type value on 0...1.
    func normalized(from range: ClosedRange<Self>, taper: Self = 0.5, aroundCenter: Bool = false) -> Self {
        if aroundCenter {
            if range.upperHalfRange.contains(self) {
                let x = self.normalized(from: range.upperHalfRange, taper: taper)
                let mapped = (x + 1.0) / 2.0
                return mapped
            } else {
                let unmapped = self.normalized(from: range.lowerHalfRange)
                let reflected = -1.0 * (unmapped - 1.0)
                let unwarped = reflected.normalized(from: 0...1, taper: taper)
                let remapped = (unwarped - 1.0) / -2.0
                return remapped
            }
        } else {
            return normalized(from: range, taper: taper)
        }
    }
    
    /// Denormalize a float-type value with variable taper.
    fileprivate func denormalized(to range: ClosedRange<Self>, taper: Self = 0.5) -> Self {
        // Taper must satisfy 0 < taper < 1
        guard taper > 0 && taper < 1 else { return range.lowerBound }
        
        // Handle the linear case.
        if taper == 0.5 {
            return range.size * self + range.lowerBound
        }
        
        // See: https://electronics.stackexchange.com/questions/304692/formula-for-logarithmic-audio-taper-pot
        else {
            let b = pow(1.0 / Double(taper) - 1.0, 2)
            let a = 1.0 / (b - 1.0)
            let y = a * pow(b, Double(self)) - a
            return range.size * Self(y) + range.lowerBound
        }
    }
    
    /// Normalize a float-type value with variable taper.
    fileprivate func normalized(from range: ClosedRange<Self>, taper: Self = 0.5) -> Self {
        // Taper must satisfy 0 < taper < 1
        guard taper > 0 && taper < 1 else { return 0.0 }
        
        // Handle the linear case.
        if taper == 0.5 {
            return (self - range.lowerBound) / range.size
        }
        
        // See: https://electronics.stackexchange.com/questions/304692/formula-for-logarithmic-audio-taper-pot
        else {
            let x = Double((self - range.lowerBound) / range.size)
            let b = pow(1.0 / Double(taper) - 1.0, 2)
            let a = 1.0 / (b - 1.0)
            return Self(log((x + a) / a) / log(b))
        }
    }
}


// MARK: - Rounding + Truncation

public extension BinaryFloatingPoint {
    /// Round a float-type value.
    /// - Parameter digits: The number of digits to which to round.
    /// - Returns: A float-type value, rounded to the appropriate number of digits.
    func rounded(digits: Int) -> Self {
        let behavior = NSDecimalNumberHandler(roundingMode: .plain,
                                              scale: Int16(digits),
                                              raiseOnExactness: false,
                                              raiseOnOverflow: false,
                                              raiseOnUnderflow: false,
                                              raiseOnDivideByZero: true)
        let decimal = NSDecimalNumber(floatLiteral: Double(self))
        let rounded = decimal.rounding(accordingToBehavior: behavior)
        return Self(rounded.doubleValue)
    }
    
    /// Truncate a float-type value.
    /// - Parameter digits: The number of digits at which to truncate.
    /// - Returns: A float-type value, truncated at the appropriate number of digits.
    func truncated(digits: Int) -> Self {
        let behavior = NSDecimalNumberHandler(roundingMode: .down,
                                              scale: Int16(digits),
                                              raiseOnExactness: false,
                                              raiseOnOverflow: false,
                                              raiseOnUnderflow: false,
                                              raiseOnDivideByZero: true)
        let decimal = NSDecimalNumber(floatLiteral: Double(self))
        let rounded = decimal.rounding(accordingToBehavior: behavior)
        return Self(rounded.doubleValue)
    }
    
    /// Get the trailing digits of a float-type value.
    func trailingDigits() -> Self {
        let integerPart = self.truncated(digits: 0)
        let trailingDigits = self - integerPart
        return trailingDigits
    }
}
