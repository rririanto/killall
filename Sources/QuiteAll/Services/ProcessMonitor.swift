import Foundation
import Darwin

public final class ProcessMonitor {
    public static let shared = ProcessMonitor()
    
    private struct PreviousCpuSample {
        let timestamp: TimeInterval
        let totalTime: UInt64 // in nanoseconds
    }
    
    private var previousSamples: [pid_t: PreviousCpuSample] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public struct ProcessMetrics {
        public let cpuPercent: Double
        public let memoryBytes: UInt64
    }
    
    /// Reads exact CPU % and resident memory bytes for a given PID.
    public func metrics(for pid: pid_t) -> ProcessMetrics {
        var pti = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.stride)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &pti, size)
        
        guard result == size else {
            return ProcessMetrics(cpuPercent: 0.0, memoryBytes: 0)
        }
        
        let residentBytes = UInt64(pti.pti_resident_size)
        let currentTotalTime = UInt64(pti.pti_total_user) + UInt64(pti.pti_total_system)
        let now = Date().timeIntervalSince1970
        
        var calculatedCpu: Double = 0.0
        
        lock.lock()
        if let previous = previousSamples[pid] {
            let deltaSeconds = now - previous.timestamp
            if deltaSeconds > 0.05 {
                let deltaNano = currentTotalTime > previous.totalTime ? (currentTotalTime - previous.totalTime) : 0
                // Convert nanoseconds to seconds, then ratio to wall time
                let cpuTimeSeconds = Double(deltaNano) / 1_000_000_000.0
                let rawPercent = (cpuTimeSeconds / deltaSeconds) * 100.0
                // Cap to reasonable multi-core range (e.g. 0 to 800%)
                calculatedCpu = max(0.0, min(rawPercent, 1600.0))
            }
        }
        previousSamples[pid] = PreviousCpuSample(timestamp: now, totalTime: currentTotalTime)
        lock.unlock()
        
        return ProcessMetrics(cpuPercent: calculatedCpu, memoryBytes: residentBytes)
    }
    
    /// Clean up cached data for terminated PIDs
    public func remove(pid: pid_t) {
        lock.lock()
        previousSamples.removeValue(forKey: pid)
        lock.unlock()
    }
}
