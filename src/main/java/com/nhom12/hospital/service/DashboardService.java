package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.HoaDon;
import com.nhom12.hospital.entity.PhieuKham;
import com.nhom12.hospital.repository.HoaDonRepository;
import com.nhom12.hospital.repository.PhieuKhamRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DashboardService {

    private final HoaDonRepository hoaDonRepository;
    private final PhieuKhamRepository phieuKhamRepository;

    public DashboardService(HoaDonRepository hoaDonRepository,
                            PhieuKhamRepository phieuKhamRepository) {
        this.hoaDonRepository = hoaDonRepository;
        this.phieuKhamRepository = phieuKhamRepository;
    }

    public Map<String, Object> getStats(LocalDate from, LocalDate to) {

        if (from.isAfter(to)) {
            throw new IllegalArgumentException(
                    "Ngày bắt đầu không được lớn hơn ngày kết thúc");
        }

        LocalDateTime fromTime = from.atStartOfDay();
        LocalDateTime toExclusive = to.plusDays(1).atStartOfDay();

        // Lọc các Phiếu khám theo thời gian
        List<PhieuKham> visits = phieuKhamRepository
                .findByNgayKhamGreaterThanEqualAndNgayKhamLessThan(
                        fromTime, toExclusive);

        // Tính tổng các trị các hóa đơn 
        List<HoaDon> paidInvoices = hoaDonRepository
                .findByTrangThaiTTAndNgayThanhToanGreaterThanEqualAndNgayThanhToanLessThan(
                        "DaThanhToan",
                        fromTime,
                        toExclusive);

        BigDecimal revenue = paidInvoices.stream()
                .map(invoice -> invoice.getTongTienDichVu().subtract(
                        invoice.getBhytChiTra() == null
                                ? BigDecimal.ZERO
                                : invoice.getBhytChiTra()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Lọc theo các chuẩn đoán khác nhau
        Map<String, Long> diagnosisCounts = new HashMap<>();

        visits.stream()
                .map(PhieuKham::getChanDoan)
                .filter(diagnosis ->
                        diagnosis != null && !diagnosis.isBlank())
                .map(String::trim)
                .forEach(diagnosis ->
                        diagnosisCounts.merge(
                                diagnosis,
                                1L,
                                Long::sum));

        Map<String, Object> res = new HashMap<>();

        res.put("from", from);
        res.put("to", to);
        res.put("totalVisits", visits.size());
        res.put("totalRevenue", revenue);

        res.put(
                "topDiseases",
                diagnosisCounts.entrySet().stream()
                        .sorted(
                                Map.Entry
                                        .<String, Long>comparingByValue()
                                        .reversed())
                        .limit(10)
                        .map(entry -> Map.of(
                                "diagnosis", entry.getKey(),
                                "count", entry.getValue()))
                        .toList()
        );

        return res;
    }

    public byte[] exportReport(LocalDate from, LocalDate to) {

    Map<String, Object> stats = getStats(from, to);

    StringBuilder csv = new StringBuilder("\uFEFFChỉ số,Giá trị\r\n")
            .append("Khoảng ngày,").append(from).append(" - ").append(to).append("\r\n")
            .append("Lượt khám,").append(stats.get("totalVisits")).append("\r\n")
            .append("Doanh thu đã thanh toán (VND),")
            .append(stats.get("totalRevenue")).append("\r\n\r\n")
            .append("Bệnh phổ biến,Lượt\r\n");

    @SuppressWarnings("unchecked")
    List<Map<String, Object>> topDiseases =
            (List<Map<String, Object>>) stats.get("topDiseases");

    for (Map<String, Object> disease : topDiseases) {
        csv.append(csvCell(String.valueOf(disease.get("diagnosis"))))
                .append(',')
                .append(disease.get("count"))
                .append("\r\n");
    }

    return csv.toString().getBytes(StandardCharsets.UTF_8);
}

private String csvCell(String value) {
    String safeValue =
            value.matches("^[\\s]*[=+@\\-].*")
                    ? "'" + value
                    : value;

    return "\"" + safeValue.replace("\"", "\"\"") + "\"";
}
}