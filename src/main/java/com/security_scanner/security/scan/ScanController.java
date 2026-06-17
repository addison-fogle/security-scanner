package com.security_scanner.security.scan;

import java.net.URI;
import java.util.List;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

@Validated
@RestController
@RequestMapping("/api/scans")
public class ScanController {

    private final ScanService scanService;

    public ScanController(ScanService scanService) {
        this.scanService = scanService;
    }

    @PostMapping
    public ResponseEntity<ScanResult> queue(@Valid @RequestBody ScanRequest request) {
        ScanResult result = scanService.queue(request);
        return ResponseEntity.created(URI.create("/api/scans/" + result.id())).body(result);
    }

    @GetMapping
    public ResponseEntity<List<ScanResult>> list() {
        return ResponseEntity.ok(scanService.list());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ScanResult> get(@PathVariable UUID id) {
        return ResponseEntity.ok(scanService.get(id));
    }
}
