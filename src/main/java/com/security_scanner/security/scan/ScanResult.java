package com.security_scanner.security.scan;

import java.time.Instant;
import java.util.UUID;

public record ScanResult(
        UUID id,
        String target,
        String type,
        ScanStatus status,
        Instant createdAt,
        Instant updatedAt,
        String summary
) {
}
