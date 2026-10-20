package com.nhom12.hospital.controller;

import com.nhom12.hospital.service.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;


@RestController
@RequestMapping("/api/v1/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    //
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats(
            @RequestParam LocalDate from,
            @RequestParam LocalDate to) {

        try {
            Map<String, Object> result =
                    dashboardService.getStats(from, to);

            return ResponseEntity.ok(result);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping(value = "/report", produces = "text/csv")
public ResponseEntity<byte[]> exportReport(
        @RequestParam LocalDate from,
        @RequestParam LocalDate to) {

    try {
        byte[] csv = dashboardService.exportReport(from, to);

        return ResponseEntity.ok()
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"hospital-report-"
                                + from + "-" + to + ".csv\"")
                .contentType(
                        new MediaType(
                                "text",
                                "csv",
                                StandardCharsets.UTF_8))
                .body(csv);

    } catch (IllegalArgumentException e) {
        return ResponseEntity.badRequest().build();
    }
}
}