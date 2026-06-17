package com.security_scanner.security.scan;

import jakarta.validation.constraints.NotBlank;

public record ScanRequest(
        @NotBlank String target,
        String type
) {
}
