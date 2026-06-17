package com.security_scanner.security.scan;

import java.util.UUID;

public class ScanNotFoundException extends RuntimeException {

    public ScanNotFoundException(UUID id) {
        super("Scan not found: " + id);
    }
}
