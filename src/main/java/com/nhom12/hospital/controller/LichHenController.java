package com.nhom12.hospital.controller;

import com.nhom12.hospital.entity.LichHen;
import com.nhom12.hospital.config.SessionAttributes;
import com.nhom12.hospital.service.LichHenService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/lichhen")
@CrossOrigin(origins = "*")
public class LichHenController {

    private final LichHenService lichHenService;

    public LichHenController(LichHenService lichHenService) {
        this.lichHenService = lichHenService;
    }

    @GetMapping("/available-slots")
    public ResponseEntity<?> getAvailableSlots(
            @RequestParam String doctorId,
            @RequestParam String date,
            @RequestParam(defaultValue = "KhamThuong") String loaiKham) {
        try {
            return ResponseEntity.ok(lichHenService.getAvailableSlots(doctorId, date, loaiKham));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<List<LichHen>> getAll(
            @RequestParam(required = false) String date,
            HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        return ResponseEntity.ok(lichHenService.getAllAppointments(accountId, date));
    }
    // Lấy lịch hẹn của bacsi
    @GetMapping("/me")
    public ResponseEntity<?> getMyAppointments(HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.getMyAppointments(accountId));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable String id, HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.getAppointmentById(id, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> req, HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            if (lichHenService.isPatient(accountId)) {
                return ResponseEntity.ok(lichHenService.createPatientAppointment(req, accountId));
            }
        return ResponseEntity.ok(lichHenService.createAdminAppointment(req));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancel(@PathVariable String id, HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.cancelAppointment(id, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/reschedule")
    public ResponseEntity<?> reschedule(@PathVariable String id,
                                        @RequestBody Map<String, String> requestBody,
                                        HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.rescheduleAppointment(id, requestBody, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            if (e.getMessage().contains("chỉ dành cho bệnh nhân") || e.getMessage().contains("hủy lịch hẹn của mình")) {
                return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
            }
            return ResponseEntity.status(409).body(Map.of("message", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/queue")
    public ResponseEntity<?> getDoctorQueue(HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.getDoctorQueue(accountId));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/checkin")
    public ResponseEntity<?> receptionistCheckin(@PathVariable String id, HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.checkinAppointment(id, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            if (e.getMessage().contains("chỉ dành cho lễ tân")) {
                return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
            }
            return ResponseEntity.status(400).body(Map.of(
                "message", "Bệnh nhân đã đến trễ quá 15 phút. Lịch hẹn tự động bị hủy.",
                "status", "DaHuy"
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
    
    @PostMapping("/{id}/start")
    public ResponseEntity<?> startExamination(@PathVariable String id, HttpServletRequest request) {
        Long accountId = (Long) request.getAttribute(SessionAttributes.ACCOUNT_ID);
        try {
            return ResponseEntity.ok(lichHenService.startExamination(id, accountId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(400).body(Map.of("message", e.getMessage()));
        }
    }
}
