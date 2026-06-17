package com.security_scanner.security.scan;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class ScanServiceTests {

    private final ScanService scanService = new ScanService();

    @Test
    void queuesScanWithDefaultType() {
        ScanResult result = scanService.queue(new ScanRequest("registry.example.com/app:latest", null));

        assertThat(result.target()).isEqualTo("registry.example.com/app:latest");
        assertThat(result.type()).isEqualTo("container");
        assertThat(result.status()).isEqualTo(ScanStatus.QUEUED);
        assertThat(scanService.list()).containsExactly(result);
    }

    @Test
    void throwsWhenScanDoesNotExist() {
        assertThatThrownBy(() -> scanService.get(java.util.UUID.randomUUID()))
                .isInstanceOf(ScanNotFoundException.class);
    }
}
