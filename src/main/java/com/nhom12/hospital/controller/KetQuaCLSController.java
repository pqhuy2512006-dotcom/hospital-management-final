package com.nhom12.hospital.controller;

import com.nhom12.hospital.config.SessionAttributes;
import com.nhom12.hospital.service.KetQuaCLSService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/cls")
@CrossOrigin(origins = "*")
public class KetQuaCLSController {

    private final KetQuaCLSService ketQuaCLSService;

    public KetQuaCLSController(KetQuaCLSService ketQuaCLSService) {
        this.ketQuaCLSService = ketQuaCLSService;
    }

    @GetMapping
    public List<Map<String, Object>> getAll() {
        return ketQuaCLSService.getAll();
    }

    @GetMapping("/me")
    public ResponseEntity<?> getMyResults(HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(ketQuaCLSService.getMyResults(accountId));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

        @PutMapping("/{id}/ketqua")
    public ResponseEntity<?> capNhatKetQua(@PathVariable String id, 
                                           @RequestBody Map<String, Object> payload,
                                           HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(ketQuaCLSService.capNhatKetQua(id, payload, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
