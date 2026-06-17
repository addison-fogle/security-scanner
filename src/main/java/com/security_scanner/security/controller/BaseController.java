package com.security_scanner.security.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BaseController {

    @GetMapping
    public ResponseEntity<String> root() {
        return ResponseEntity.ok("security-scanner");
    }
}
