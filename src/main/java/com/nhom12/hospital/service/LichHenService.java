package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.BenhNhan;
import com.nhom12.hospital.entity.LichHen;
import com.nhom12.hospital.entity.NhanVien;
import com.nhom12.hospital.entity.TaiKhoan;
import com.nhom12.hospital.repository.BenhNhanRepository;
import com.nhom12.hospital.repository.KhoaRepository;
import com.nhom12.hospital.repository.LichHenRepository;
import com.nhom12.hospital.repository.NhanVienRepository;
import com.nhom12.hospital.repository.TaiKhoanRepository;
import org.springframework.stereotype.Service;
import com.nhom12.hospital.entity.Khoa;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

@Service
public class LichHenService {

    private final LichHenRepository lichHenRepository;
    private final BenhNhanRepository benhNhanRepository;
    private final KhoaRepository khoaRepository;
    private final NhanVienRepository nhanVienRepository;
    private final TaiKhoanRepository taiKhoanRepository;

    public LichHenService(LichHenRepository lichHenRepository,
                          BenhNhanRepository benhNhanRepository,
                          KhoaRepository khoaRepository,
                          NhanVienRepository nhanVienRepository,
                          TaiKhoanRepository taiKhoanRepository) {
        this.lichHenRepository = lichHenRepository;
        this.benhNhanRepository = benhNhanRepository;
        this.khoaRepository = khoaRepository;
        this.nhanVienRepository = nhanVienRepository;
        this.taiKhoanRepository = taiKhoanRepository;
    }

    public List<String> getAvailableSlots(String doctorId, String date, String loaiKham) {
        LocalDate kDate;
        try {
            kDate = LocalDate.parse(date);
        } catch (Exception e) {
            throw new IllegalArgumentException("Ngày khám không hợp lệ.");
        }

        if (kDate.isBefore(LocalDate.now())) {
            return List.of(); // No slots in the past
        }

        Integer duration = expectedDuration(loaiKham);
        if (duration == null) duration = 30;

        List<LichHen> existing = lichHenRepository.findByMaBacSiAndNgayKham(doctorId, kDate).stream()
                .filter(lh -> !"DaHuy".equalsIgnoreCase(lh.getTrangThai()))
                .toList();

        List<String> availableSlots = new ArrayList<>();
        // Khung giờ sáng: 08:00 - 11:30
        generateSlots(availableSlots, existing, kDate, LocalTime.of(8, 0), LocalTime.of(11, 30), duration);
        // Khung giờ chiều: 13:00 - 16:30
        generateSlots(availableSlots, existing, kDate, LocalTime.of(13, 0), LocalTime.of(16, 30), duration);

        return availableSlots;
    }

    private void generateSlots(List<String> availableSlots, List<LichHen> existing, LocalDate kDate, LocalTime start, LocalTime end, int duration) {
        LocalTime current = start;
        LocalDateTime now = LocalDateTime.now();
        while (!current.plusMinutes(duration).isAfter(end)) {
            LocalDateTime slotStart = LocalDateTime.of(kDate, current);
            if (slotStart.isAfter(now)) { // Only future slots
                LocalDateTime slotEnd = slotStart.plusMinutes(duration);
                boolean conflict = existing.stream().anyMatch(lh -> {
                    Integer exDur = lh.getThoiGianKhamDuKien() != null ? lh.getThoiGianKhamDuKien() : expectedDuration(lh.getLoaiKham());
                    if (exDur == null || lh.getGioKham() == null) return false;
                    LocalDateTime exStart = LocalDateTime.of(lh.getNgayKham(), lh.getGioKham());
                    LocalDateTime exEnd = exStart.plusMinutes(exDur);
                    return exStart.isBefore(slotEnd) && slotStart.isBefore(exEnd);
                });
                if (!conflict) {
                    availableSlots.add(current.toString());
                }
            }
            current = current.plusMinutes(30); // Giả sử mỗi slot cách nhau 30p để dễ nhìn
        }
    }

    public List<LichHen> getAllAppointments(Long accountId, String dateParam) {
        if (accountId != null && isDoctor(accountId)) {
            List<LichHen> list = findCurrentDoctor(accountId)
                    .map(doctor -> lichHenRepository.findByMaBacSi(doctor.getMaNhanVien()))
                    .orElseGet(List::of);
            if (dateParam != null && !dateParam.isBlank()) {
                list = list.stream().filter(lh -> java.time.LocalDate.parse(dateParam).equals(lh.getNgayKham())).toList();
            }
            return list;
        }
        if (accountId != null && isReceptionist(accountId)) {
            java.time.LocalDate targetDate = (dateParam != null && !dateParam.isBlank()) 
                    ? java.time.LocalDate.parse(dateParam) : java.time.LocalDate.now();
            return lichHenRepository.findAll().stream()
                    .filter(lh -> targetDate.equals(lh.getNgayKham()))
                    .toList();
        }
        List<LichHen> all = lichHenRepository.findAll();
        if (dateParam != null && !dateParam.isBlank()) {
            all = all.stream().filter(lh -> java.time.LocalDate.parse(dateParam).equals(lh.getNgayKham())).toList();
        }
        return all;
    }

    public List<LichHen> getMyAppointments(Long accountId) {
        if (accountId == null) {
            throw new IllegalStateException("Yêu cầu đăng nhập.");
        }
        if (isPatient(accountId)) {
            return benhNhanRepository.findByMaTaiKhoan(accountId)
                    .map(patient -> lichHenRepository.findByMaBenhNhan(patient.getMaBenhNhan()))
                    .orElseThrow(() -> new NoSuchElementException("Không tìm thấy hồ sơ bệnh nhân."));
        }
        Optional<NhanVien> doctor = nhanVienRepository.findByMaTaiKhoan(accountId)
                .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
        if (doctor.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }
        return lichHenRepository.findByMaBacSi(doctor.get().getMaNhanVien());
    }

    public LichHen getAppointmentById(String id, Long accountId) {
        Optional<LichHen> appointment = lichHenRepository.findById(id);
        if (appointment.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy lịch hẹn.");
        }
        if (accountId != null && isDoctor(accountId) && findCurrentDoctor(accountId)
                .filter(doctor -> doctor.getMaNhanVien().equals(appointment.get().getMaBacSi())).isEmpty()) {
            throw new IllegalStateException("Không có quyền truy cập lịch hẹn này.");
        }
        return appointment.get();
    }

    public Optional<NhanVien> findCurrentDoctor(Long accountId) {
        return accountId == null ? Optional.empty() : nhanVienRepository.findByMaTaiKhoan(accountId)
                .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
    }

    public boolean isDoctor(Long accountId) {
        return accountId != null && taiKhoanRepository.findById(accountId)
                .map(TaiKhoan::getVaiTro)
                .filter("BacSi"::equalsIgnoreCase)
                .isPresent();
    }
    
    public boolean isPatient(Long accountId) {
        return accountId != null && taiKhoanRepository.findById(accountId)
                .map(TaiKhoan::getVaiTro)
                .filter("BenhNhan"::equalsIgnoreCase)
                .isPresent();
    }
    
    public boolean isReceptionist(Long accountId) {
        return accountId != null && taiKhoanRepository.findById(accountId)
                .map(TaiKhoan::getVaiTro)
                .filter("LeTan"::equalsIgnoreCase)
                .isPresent();
    }

    public LichHen createAdminAppointment(Map<String, Object> req) {
        try {
            String maLH = "LH2026" + String.format("%06d", lichHenRepository.count() + 1);
            LichHen lh = new LichHen();
            lh.setMaLichHen(maLH);

            // Xử lý bệnh nhân: có thể gửi maBenhNhan hoặc tên bệnh nhân
            String maBN = req.get("maBenhNhan") != null ? String.valueOf(req.get("maBenhNhan")) : null;
            String tenBN = req.get("patientName") != null ? String.valueOf(req.get("patientName")) : null;
            String cccd = req.get("cccd") != null ? String.valueOf(req.get("cccd")) : null;

            if (maBN == null || maBN.trim().isEmpty()) {
                // Tìm theo CCCD nếu có
                if (cccd != null && !cccd.trim().isEmpty()) {
                    String finalCccd = cccd;
                    Optional<BenhNhan> bnOpt = benhNhanRepository.findAll().stream()
                            .filter(b -> finalCccd.equals(b.getSoCCCD()))
                            .findFirst();
                    if (bnOpt.isPresent()) {
                        maBN = bnOpt.get().getMaBenhNhan();
                    }
                }
                // Nếu vẫn chưa có, tạo nhanh bệnh nhân mới
                if (maBN == null || maBN.trim().isEmpty()) {
                    if (cccd == null || cccd.trim().isEmpty()) {
                        throw new IllegalArgumentException("Vui lòng cung cấp Số Căn cước công dân để tạo hồ sơ bệnh nhân mới.");
                    }
                    BenhNhan newBn = new BenhNhan();
                    newBn.setMaBenhNhan("BN2026" + String.format("%06d", benhNhanRepository.count() + 1));
                    newBn.setHoTen(tenBN != null && !tenBN.trim().isEmpty() ? tenBN : "Bệnh nhân mới");
                    newBn.setNgaySinh(LocalDate.of(1990, 1, 1));
                    newBn.setGioiTinh("Nam");
                    newBn.setSoCCCD(cccd);
                    newBn.setSoDienThoai("09" + (int)(Math.random() * 90000000 + 10000000));
                    newBn.setNgayTaoHoSo(LocalDateTime.now());
                    BenhNhan savedBn = benhNhanRepository.save(newBn);
                    maBN = savedBn.getMaBenhNhan();
                }
            }
            lh.setMaBenhNhan(maBN);

            // Xử lý khoa
            String maKhoa = req.get("maKhoa") != null ? String.valueOf(req.get("maKhoa")) : null;
            if (maKhoa == null || maKhoa.trim().isEmpty()) {
                String deptName = req.get("dept") != null ? String.valueOf(req.get("dept")) : null;
                if (deptName != null) {
                    if (deptName.contains("Nội")) maKhoa = "KNT";
                    else if (deptName.contains("Ngoại")) maKhoa = "KNG";
                    else if (deptName.contains("Tai")) maKhoa = "TMH";
                    else if (deptName.contains("Cấp Cứu")) maKhoa = "KCC";
                    else maKhoa = "KKB";
                } else {
                    maKhoa = "KKB";
                }
            }
            lh.setMaKhoa(maKhoa);

            lh.setMaBacSi(req.get("maBacSi") != null ? String.valueOf(req.get("maBacSi")) : "NV-DOC01");
            lh.setNgayKham(req.get("ngayKham") != null ? LocalDate.parse(req.get("ngayKham").toString()) : LocalDate.now());

            String gioKhamStr = req.get("gioKham") != null ? String.valueOf(req.get("gioKham")) : null;
            if (gioKhamStr != null && gioKhamStr.length() >= 5) {
                try {
                    lh.setGioKham(LocalTime.parse(gioKhamStr.substring(0, 5) + ":00"));
                } catch (Exception e) {
                    lh.setGioKham(LocalTime.of(8, 30));
                }
            } else {
                lh.setGioKham(LocalTime.of(8, 30));
            }

            lh.setLoaiKham(req.get("loaiKham") != null ? String.valueOf(req.get("loaiKham")) : "KhamThuong");
            Integer duration = expectedDuration(lh.getLoaiKham());
            if (duration == null) {
                throw new IllegalArgumentException("Loại khám không hợp lệ.");
            }
            lh.setThoiGianKhamDuKien(duration);
            lh.setHinhThucDat(req.get("hinhThucDat") != null ? String.valueOf(req.get("hinhThucDat")) : "Online");
            lh.setLyDoKham(req.get("lyDoKham") != null ? String.valueOf(req.get("lyDoKham")) : null);
            lh.setTrangThai("DaDatLich");
            lh.setNgayDatLich(LocalDateTime.now());

            if (hasScheduleConflict(lh, null)) {
                throw new IllegalStateException("Bác sĩ đã có lịch khám giao với khung giờ này.");
            }
            return lichHenRepository.save(lh);
        } catch (RuntimeException error) {
            if (error instanceof IllegalArgumentException || error instanceof IllegalStateException) {
                throw error;
            }
            throw new IllegalArgumentException("Dữ liệu đầu vào không hợp lệ: " + error.getMessage());
        }
    }

    public LichHen createPatientAppointment(Map<String, Object> requestBody, Long accountId) {
        Optional<BenhNhan> patient = accountId == null
                ? Optional.empty()
                : benhNhanRepository.findByMaTaiKhoan(accountId);
        if (patient.isEmpty()) {
            throw new IllegalStateException("Vui lòng tạo hồ sơ bệnh nhân trước khi đặt lịch.");
        }
        try {
            LocalDate date = LocalDate.parse(String.valueOf(requestBody.get("ngayKham")));
            LocalTime time = LocalTime.parse(String.valueOf(requestBody.get("gioKham")));
            if (!LocalDateTime.of(date, time).isAfter(LocalDateTime.now())) {
                throw new IllegalArgumentException("Thời gian khám phải ở trong tương lai.");
            }
            String departmentId = String.valueOf(requestBody.get("maKhoa"));
            String doctorId = String.valueOf(requestBody.get("maBacSi"));
                        Optional<Khoa> khoaOpt = khoaRepository.findById(departmentId);
            if (khoaOpt.isEmpty()) {
                throw new IllegalArgumentException("Khoa khám không hợp lệ.");
            }
            if (Boolean.FALSE.equals(khoaOpt.get().getTrangThai())) {
                throw new IllegalArgumentException("Khoa " + khoaOpt.get().getTenKhoa() + " hiện đang tạm ngưng tiếp nhận, vui lòng chọn khoa khác.");
            }
            Optional<NhanVien> doctor = nhanVienRepository.findById(doctorId)
                    .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()))
                    .filter(employee -> !"DaNghi".equalsIgnoreCase(employee.getTrangThai()));
            if (doctor.isEmpty()) {
                throw new IllegalArgumentException("Bác sĩ được chọn không hợp lệ.");
            }

            LichHen appointment = new LichHen();
            appointment.setMaLichHen("LH2026" + String.format("%06d", lichHenRepository.count() + 1));
            appointment.setMaBenhNhan(patient.get().getMaBenhNhan());
            appointment.setMaKhoa(departmentId);
            appointment.setMaBacSi(doctorId);
            appointment.setNgayKham(date);
            appointment.setGioKham(time);
            String visitType = String.valueOf(requestBody.getOrDefault("loaiKham", "KhamThuong"));
            Integer duration = expectedDuration(visitType);
            if (duration == null) {
                throw new IllegalArgumentException("Loại khám không hợp lệ.");
            }
            appointment.setLoaiKham(visitType);
            appointment.setThoiGianKhamDuKien(duration);
            appointment.setHinhThucDat("Online");
            appointment.setLyDoKham((String) requestBody.get("lyDoKham"));
            appointment.setTrangThai("DaDatLich");
            appointment.setNgayDatLich(LocalDateTime.now());
            if (hasScheduleConflict(appointment, null)) {
                throw new IllegalStateException("Bác sĩ đã có lịch khám giao với khung giờ này.");
            }
            return lichHenRepository.save(appointment);
        } catch (RuntimeException error) {
            if(error instanceof IllegalArgumentException || error instanceof IllegalStateException) {
                throw error;
            }
            throw new IllegalArgumentException("Ngày, giờ, khoa hoặc bác sĩ không hợp lệ.");
        }
    }

    // 👉 TÌM HÀM cancelAppointment VÀ CẬP NHẬT NHƯ SAU:
    public LichHen cancelAppointment(String id, Long accountId) {
        Optional<LichHen> appointment = lichHenRepository.findById(id);
        if (appointment.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy lịch hẹn.");
        }
        LichHen current = appointment.get();

        // Chặn không cho hủy lịch đã khám xong hoặc đang trong phòng khám
        if ("DaKham".equalsIgnoreCase(current.getTrangThai()) || "DangKham".equalsIgnoreCase(current.getTrangThai())) {
            throw new IllegalStateException("Lịch hẹn đang diễn ra hoặc đã hoàn tất khám, không thể hủy.");
        }
        if ("DaHuy".equalsIgnoreCase(current.getTrangThai())) {
            throw new IllegalStateException("Lịch hẹn này đã bị hủy trước đó.");
        }

        if (accountId != null && isPatient(accountId)) {
            if (!ownsAppointment(current, accountId)) {
                throw new IllegalStateException("Bạn chỉ được hủy lịch hẹn của mình.");
            }
            if (!canPatientChange(current)) {
                throw new IllegalArgumentException("Chỉ được hủy lịch hẹn trước giờ khám tối thiểu 4 tiếng.");
            }
        }
        current.setTrangThai("DaHuy");
        return lichHenRepository.save(current);
    }

    public LichHen rescheduleAppointment(String id, Map<String, String> requestBody, Long accountId) {
        if (accountId == null || !isPatient(accountId)) {
            throw new IllegalStateException("Chức năng này chỉ dành cho bệnh nhân.");
        }
        Optional<LichHen> appointment = lichHenRepository.findById(id);
        if (appointment.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy lịch hẹn.");
        }
        LichHen current = appointment.get();
        if (!ownsAppointment(current, accountId)) {
            throw new IllegalStateException("Bạn chỉ được đổi lịch hẹn của mình.");
        }
        if (!canPatientChange(current)) {
            throw new IllegalArgumentException("Chỉ được đổi lịch trước giờ khám hơn 4 tiếng.");
        }
        try {
            LocalDate newDate = LocalDate.parse(requestBody.get("ngayKham"));
            LocalTime newTime = LocalTime.parse(requestBody.get("gioKham"));
            if (!LocalDateTime.of(newDate, newTime).isAfter(LocalDateTime.now())) {
                throw new IllegalArgumentException("Thời gian hẹn mới phải ở trong tương lai.");
            }
            Integer duration = expectedDuration(current.getLoaiKham());
            if (duration == null) {
                throw new IllegalArgumentException("Loại khám của lịch hẹn không hợp lệ.");
            }
            current.setNgayKham(newDate);
            current.setGioKham(newTime);
            current.setThoiGianKhamDuKien(duration);
            if (hasScheduleConflict(current, id)) {
                throw new IllegalStateException("Bác sĩ đã có lịch khám giao với khung giờ này.");
            }
            return lichHenRepository.save(current);
        } catch (RuntimeException error) {
            if(error instanceof IllegalArgumentException || error instanceof IllegalStateException) {
                throw error;
            }
            throw new IllegalArgumentException("Ngày hoặc giờ khám không hợp lệ.");
        }
    }

    public List<Map<String, Object>> getDoctorQueue(Long accountId) {
        if (accountId == null || !isDoctor(accountId)) {
            throw new IllegalStateException("Chức năng này chỉ dành cho bác sĩ.");
        }
        Optional<NhanVien> doctor = findCurrentDoctor(accountId);
        if (doctor.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }
        return lichHenRepository.getQueueForDoctor(doctor.get().getMaNhanVien(), LocalDate.now());
    }

    public Map<String, String> checkinAppointment(String id, Long accountId) {
        if (accountId == null || !isReceptionist(accountId)) {
            throw new IllegalStateException("Chức năng này chỉ dành cho lễ tân.");
        }
        Optional<LichHen> appointment = lichHenRepository.findById(id);
        if (appointment.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy lịch hẹn.");
        }
        LichHen current = appointment.get();
        if (!"DaDatLich".equalsIgnoreCase(current.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể check-in lịch hẹn ở trạng thái Đã đặt lịch.");
        }
        
        LocalDateTime scheduledTime = LocalDateTime.of(current.getNgayKham(), current.getGioKham());
        
        if (LocalDateTime.now().isBefore(scheduledTime.minusMinutes(30))) {
            throw new IllegalArgumentException("Chỉ được check-in trước giờ khám tối đa 30 phút.");
        }

        if (LocalDateTime.now().isAfter(scheduledTime.plusMinutes(15))) {
            current.setTrangThai("DaHuy");
            lichHenRepository.save(current);
            throw new IllegalStateException("Bệnh nhân đã đến trễ quá 15 phút. Lịch hẹn tự động bị hủy.");
        }
        
        current.setTrangThai("DangChoKham");
        lichHenRepository.save(current);
        return Map.of("message", "Check-in thành công", "status", "DangChoKham");
    }

    public Map<String, String> startExamination(String id, Long accountId) {
        if (accountId == null || !isDoctor(accountId)) {
            throw new IllegalStateException("Chỉ bác sĩ mới có quyền tiếp nhận.");
        }
        Optional<LichHen> appointment = lichHenRepository.findById(id);
        if (appointment.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy lịch hẹn.");
        }
        LichHen current = appointment.get();
        Optional<NhanVien> doctor = findCurrentDoctor(accountId);
        if (doctor.isEmpty() || !doctor.get().getMaNhanVien().equals(current.getMaBacSi())) {
            throw new IllegalStateException("Bạn không được phép khám ca này.");
        }
        
        try {
            // Sinh mã phiếu khám ngẫu nhiên theo định dạng PK + time
            String maPhieuKham = "PK" + id.substring(id.length() > 6 ? id.length() - 6 : 0) + (System.currentTimeMillis() % 10000);
            lichHenRepository.startExamination(id, maPhieuKham, current.getMaBacSi(), current.getMaKhoa());
            return Map.of("message", "Bắt đầu khám thành công.", "maPhieuKham", maPhieuKham);
        } catch (org.springframework.dao.DataAccessException e) {
            String errorMsg = e.getMessage() != null ? e.getMessage() : "Lỗi không xác định khi tiếp nhận bệnh nhân.";
            // Trích xuất câu thông báo lỗi thực tế từ SQL Server (RAISERROR)
            if (errorMsg.contains("Bệnh nhân đã đến trễ quá 10 phút")) {
                throw new IllegalArgumentException("Bệnh nhân đã đến trễ quá 10 phút. Lịch hẹn đã bị tự động hủy!");
            }
            throw new IllegalArgumentException("Không thể bắt đầu khám: " + errorMsg);
        }
    }

    private boolean ownsAppointment(LichHen appointment, Long accountId) {
        return accountId != null && benhNhanRepository.findByMaTaiKhoan(accountId)
                .map(patient -> patient.getMaBenhNhan().equals(appointment.getMaBenhNhan()))
                .orElse(false);
    }

     private boolean canPatientChange(LichHen appointment) {
        if (appointment.getNgayKham() == null || appointment.getGioKham() == null
                || "DaHuy".equalsIgnoreCase(appointment.getTrangThai())
                || "DangKham".equalsIgnoreCase(appointment.getTrangThai())
                || "DaKham".equalsIgnoreCase(appointment.getTrangThai())) {
            return false;
        }
        return !LocalDateTime.of(appointment.getNgayKham(), appointment.getGioKham())
            .isBefore(LocalDateTime.now().plusHours(4));
    }

    private Integer expectedDuration(String visitType) {
        if ("KhamThuong".equals(visitType) || "TaiKham".equals(visitType)) {
            return 30;
        }
        if ("KhamDichVu".equals(visitType)) {
            return 45;
        }
        return null;
    }

    private boolean hasScheduleConflict(LichHen candidate, String excludedAppointmentId) {
        if (candidate.getMaBacSi() == null || candidate.getNgayKham() == null
                || candidate.getGioKham() == null || candidate.getThoiGianKhamDuKien() == null) {
            return false;
        }
        LocalDateTime candidateStart = LocalDateTime.of(candidate.getNgayKham(), candidate.getGioKham());
        LocalDateTime candidateEnd = candidateStart.plusMinutes(candidate.getThoiGianKhamDuKien());
        return lichHenRepository.findByMaBacSiAndNgayKham(candidate.getMaBacSi(), candidate.getNgayKham()).stream()
                .filter(existing -> !"DaHuy".equalsIgnoreCase(existing.getTrangThai()))
                .filter(existing -> excludedAppointmentId == null
                        || !excludedAppointmentId.equals(existing.getMaLichHen()))
                .anyMatch(existing -> {
                    Integer existingDuration = existing.getThoiGianKhamDuKien() != null
                            ? existing.getThoiGianKhamDuKien()
                            : expectedDuration(existing.getLoaiKham());
                    if (existingDuration == null || existing.getGioKham() == null) {
                        return false;
                    }
                    LocalDateTime existingStart = LocalDateTime.of(existing.getNgayKham(), existing.getGioKham());
                    LocalDateTime existingEnd = existingStart.plusMinutes(existingDuration);
                    return existingStart.isBefore(candidateEnd) && candidateStart.isBefore(existingEnd);
                });
    }
}

