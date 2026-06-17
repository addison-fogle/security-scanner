package com.security_scanner.security.scan;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

@Service
public class ScanService {

    private final Map<UUID, ScanResult> scans = new ConcurrentHashMap<>();

    public ScanResult queue(ScanRequest request) {
        Instant now = Instant.now();
        String scanType = request.type() == null || request.type().isBlank() ? "container" : request.type();
        ScanResult result = new ScanResult(
                UUID.randomUUID(),
                request.target(),
                scanType,
                ScanStatus.QUEUED,
                now,
                now,
                "Scan queued");
        scans.put(result.id(), result);
        return result;
    }

    public List<ScanResult> list() {
        return scans.values().stream()
                .sorted(Comparator.comparing(ScanResult::createdAt).reversed())
                .toList();
    }

    public ScanResult get(UUID id) {
        ScanResult result = scans.get(id);
        if (result == null) {
            throw new ScanNotFoundException(id);
        }
        return result;
    }
}
