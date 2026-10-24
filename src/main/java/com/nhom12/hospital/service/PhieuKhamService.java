package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.*;
import com.nhom12.hospital.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalTime;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class PhieuKhamService {

    private final PhieuKhamRepository phieuKhamRepository;
    private final DonThuocRepository donThuocRepository;
    private final ThuocRepository thuocRepository;
    private final LichHenRepository lichHenRepository;
    private final KetQuaCLSRepository ketQuaCLSRepository;
    private final DichVuCLSRepository dichVuCLSRepository;
    private final HoaDonRepository hoaDonRepository;
    private final ChiTietHoaDonRepository chiTietHoaDonRepository;
    private final BenhNhanRepository benhNhanRepository;
    private final NhanVienRepository nhanVienRepository;
    private final KhoaRepository khoaRepository;

    public PhieuKhamService(PhieuKhamRepository phieuKhamRepository,
                            DonThuocRepository donThuocRepository,
                            ThuocRepository thuocRepository,
                            LichHenRepository lichHenRepository,
                            KetQuaCLSRepository ketQuaCLSRepository,
                            DichVuCLSRepository dichVuCLSRepository,
                            HoaDonRepository hoaDonRepository,
                            ChiTietHoaDonRepository chiTietHoaDonRepository,
                            BenhNhanRepository benhNhanRepository,
                            NhanVienRepository nhanVienRepository,
                            KhoaRepository khoaRepository) {
        this.phieuKhamRepository = phieuKhamRepository;
        this.donThuocRepository = phieuKhamRepository != null ? donThuocRepository : donThuocRepository;
        this.thuocRepository = thuocRepository;
        this.lichHenRepository = lichHenRepository;
        this.ketQuaCLSRepository = ketQuaCLSRepository;
        this.dichVuCLSRepository = dichVuCLSRepository;
        this.hoaDonRepository = hoaDonRepository;
        this.chiTietHoaDonRepository = chiTietHoaDonRepository;
        this.benhNhanRepository = benhNhanRepository;
        this.nhanVienRepository = nhanVienRepository;
        this.khoaRepository = khoaRepository;
    }

    public List<PhieuKham> getAll() {
        return phieuKhamRepository.findAll();
    }

    public List<PhieuKham> getMyExaminations(Long accountId) {
        if (accountId == null) {
            throw new IllegalStateException("Yêu cầu đăng nhập.");
        }
        Optional<NhanVien> doctor = nhanVienRepository.findByMaTaiKhoan(accountId)
                .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
        if (doctor.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }
        return phieuKhamRepository.findByMaBacSi(doctor.get().getMaNhanVien());
    }

    public Optional<Map<String, Object>> getById(String id) {
        return phieuKhamRepository.findById(id).map(pk -> {
            Map<String, Object> map = new HashMap<>();
            map.put("phieuKham", pk);
            map.put("donThuoc", donThuocRepository.findByMaPhieuKham(id));
            map.put("tongTienThuoc", donThuocRepository.tinhTongTienThuocTheoPhieuKham(id));
            map.put("ketQuaCLS", ketQuaCLSRepository.findByMaPhieuKham(id));
            benhNhanRepository.findById(pk.getMaBenhNhan()).ifPresent(bn -> map.put("benhNhan", bn));
            return map;
        });
    }

    @Transactional
    public Map<String, Object> hoanTatKham(Map<String, Object> payload, Long accountId) {
        Optional<NhanVien> doctorOpt = accountId == null ? Optional.empty()
                : nhanVienRepository.findByMaTaiKhoan(accountId)
                        .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
        if (doctorOpt.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }

        String rawLichHen = (String) payload.get("maLichHen");
        Optional<LichHen> appointmentOpt = rawLichHen == null ? Optional.empty() : lichHenRepository.findById(rawLichHen);
        if (appointmentOpt.isEmpty()
                || !doctorOpt.get().getMaNhanVien().equals(appointmentOpt.get().getMaBacSi())
                || "DaKham".equalsIgnoreCase(appointmentOpt.get().getTrangThai())) {
            throw new IllegalArgumentException("Lịch khám không hợp lệ, không thuộc bác sĩ hoặc đã hoàn tất.");
        }

        LichHen appointment = appointmentOpt.get();

        Optional<PhieuKham> existingPk = phieuKhamRepository.findByMaLichHen(appointment.getMaLichHen());
        if (existingPk.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy Phiếu khám. Vui lòng bấm Bắt đầu khám trước.");
        }
        PhieuKham pk = existingPk.get();
        String maPK = pk.getMaPhieuKham();

        List<KetQuaCLS> existingResults = ketQuaCLSRepository.findByMaPhieuKham(maPK);
        boolean hasPendingTests = existingResults.stream()
                .anyMatch(kq -> kq.getKetLuan() == null || kq.getKetLuan().trim().isEmpty());
        if (hasPendingTests) {
            throw new IllegalArgumentException("Bệnh nhân đang có xét nghiệm chưa có kết quả. Vui lòng cập nhật kết quả xét nghiệm trước khi hoàn tất khám.");
        }

        pk.setNgayKham(LocalDateTime.now());
        pk.setTrieuChung((String) payload.get("trieuChung"));
        pk.setChanDoan((String) payload.getOrDefault("chanDoan", "Viêm họng cấp"));
        pk.setLoiDanBacSi((String) payload.get("loiDanBacSi"));

        if (payload.get("mach") != null) pk.setMach(Integer.parseInt(payload.get("mach").toString()));
        if (payload.get("nhietDo") != null) pk.setNhietDo(new BigDecimal(payload.get("nhietDo").toString()));
        if (payload.get("huyetAp") != null) pk.setHuyetAp((String) payload.get("huyetAp"));
        if (payload.get("nhipTho") != null) pk.setNhipTho(Integer.parseInt(payload.get("nhipTho").toString()));

        // XỬ LÝ HẸN TÁI KHÁM:
        String rawNgayHen = (String) payload.get("ngayHenTaiKham");
        String rawGioHen = (String) payload.get("gioHenTaiKham");

        if (rawNgayHen != null && !rawNgayHen.trim().isEmpty()) {
            LocalDate ngayHen = LocalDate.parse(rawNgayHen.trim());
            pk.setNgayHenTaiKham(ngayHen);

            // Tự động tạo 1 lịch hẹn tái khám mới
            LichHen lhMoi = new LichHen();
            lhMoi.setMaLichHen("LH" + (System.currentTimeMillis() % 10000000));
            lhMoi.setMaBenhNhan(pk.getMaBenhNhan());
            lhMoi.setMaKhoa(pk.getMaKhoa());
            lhMoi.setMaBacSi(pk.getMaBacSi()); // Khám với chính bác sĩ điều trị
            lhMoi.setNgayKham(ngayHen);

            LocalTime gioHen = (rawGioHen != null && !rawGioHen.trim().isEmpty())
                    ? LocalTime.parse(rawGioHen.trim())
                    : LocalTime.of(8, 30);
            lhMoi.setGioKham(gioHen);

            lhMoi.setLoaiKham("TaiKham");
            lhMoi.setThoiGianKhamDuKien(30); // 30 phút theo chuẩn DB
            lhMoi.setHinhThucDat("TrucTiep");
            lhMoi.setLyDoKham("Tái khám theo hẹn: " + pk.getChanDoan());
            lhMoi.setTrangThai("DaDatLich");
            lhMoi.setNgayDatLich(LocalDateTime.now());

            lichHenRepository.save(lhMoi);
        }

        phieuKhamRepository.save(pk);

        if (pk.getMaLichHen() != null) {
            lichHenRepository.findById(pk.getMaLichHen()).ifPresent(lh -> {
                lh.setTrangThai("DaKham");
                lichHenRepository.save(lh);
            });
        }

        String maHD = "HD" + (System.currentTimeMillis() % 10000000);
        List<ChiTietHoaDon> billItems = new ArrayList<>();
        BigDecimal totalSum = BigDecimal.ZERO;

        ChiTietHoaDon cthdKham = new ChiTietHoaDon();
        cthdKham.setMaChiTietHD("CTHD" + (System.currentTimeMillis() % 1000000) + "_1");
        cthdKham.setMaHoaDon(maHD);
        cthdKham.setTenDichVu("Công khám chuyên khoa");
        cthdKham.setLoaiDichVu("Kham");
        cthdKham.setDonGia(BigDecimal.valueOf(150000));
        cthdKham.setSoLuong(1);
        billItems.add(cthdKham);
        totalSum = totalSum.add(cthdKham.getDonGia());

        List<DonThuoc> donThuocList = new ArrayList<>();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> meds = (List<Map<String, Object>>) payload.get("donThuoc");
        if (meds != null && !meds.isEmpty()) {
            int seq = 1;
            for (Map<String, Object> m : meds) {
                String maThuoc = (String) m.get("maThuoc");
                int qty = Integer.parseInt(m.getOrDefault("soLuong", 1).toString());
                String cachDung = (String) m.getOrDefault("cachDung", "Uống sau ăn");
                String lieuDung = (String) m.getOrDefault("lieuDung", "Theo chỉ định");

                DonThuoc dt = new DonThuoc();
                dt.setMaDonThuoc("DT" + (System.currentTimeMillis() % 1000000) + "_" + seq++);
                dt.setMaPhieuKham(maPK);
                dt.setMaThuoc(maThuoc);
                dt.setSoLuong(qty);
                dt.setDonViTinh((String) m.getOrDefault("donViTinh", "Vien"));
                dt.setCachDung(cachDung);
                dt.setLieuDung(lieuDung);
                donThuocList.add(dt);

                Optional<Thuoc> drugOpt = thuocRepository.findById(maThuoc);
                if (drugOpt.isPresent()) {
                    Thuoc drug = drugOpt.get();

                    ChiTietHoaDon cthdMed = new ChiTietHoaDon();
                    cthdMed.setMaChiTietHD("CTHD" + (System.currentTimeMillis() % 1000000) + "_" + seq);
                    cthdMed.setMaHoaDon(maHD);
                    cthdMed.setTenDichVu(drug.getTenThuoc());
                    cthdMed.setLoaiDichVu("Thuoc");
                    cthdMed.setDonGia(drug.getDonGiaBan());
                    cthdMed.setSoLuong(qty);
                    billItems.add(cthdMed);
                }
            }
        }

        // Lưu đơn thuốc trước và tính tổng tiền thuốc bằng hàm SQL dbo.fn_TinhTongTienThuocTheoPhieuKham
        donThuocRepository.saveAll(donThuocList);
        BigDecimal tongTienThuoc = donThuocRepository.tinhTongTienThuocTheoPhieuKham(maPK);
        totalSum = totalSum.add(tongTienThuoc);

        List<KetQuaCLS> clsOrders = new ArrayList<>();
        boolean isClsPaused = false;
        List<?> clsList = (List<?>) payload.get("clsList");
        if (clsList != null && !clsList.isEmpty()) {
            int clsSeq = 1;
            for (Object item : clsList) {
                String maDV = null;
                if (item instanceof String s) {
                    maDV = s;
                } else if (item instanceof Map<?, ?> m) {
                    maDV = (String) m.get("maDichVu");
                }
                if (maDV == null || maDV.trim().isEmpty()) continue;

                final int currentSeq = clsSeq++;
                final String finalMaDV = maDV;
                Optional<DichVuCLS> dvOpt = dichVuCLSRepository.findById(finalMaDV);
                if (dvOpt.isPresent()) {
                    DichVuCLS dv = dvOpt.get();
                    String maKQ = "CLS" + (System.currentTimeMillis() % 1000000) + "_" + currentSeq;
                    KetQuaCLS kq = new KetQuaCLS();
                    kq.setMaKetQua(maKQ);
                    kq.setMaPhieuKham(maPK);
                    kq.setMaBenhNhan(pk.getMaBenhNhan());
                    kq.setMaDichVu(finalMaDV);
                    kq.setMaKTV("NV-LAB01");
                    kq.setMaBacSiDoc(pk.getMaBacSi());
                    kq.setLoaiXetNghiem(dv.getTenDichVu());
                    kq.setNgayThucHien(LocalDateTime.now());
                    clsOrders.add(kq);

                    ChiTietHoaDon cthdCLS = new ChiTietHoaDon();
                    cthdCLS.setMaChiTietHD("CTHD" + (System.currentTimeMillis() % 1000000) + "_CLS" + currentSeq);
                    cthdCLS.setMaHoaDon(maHD);
                    cthdCLS.setTenDichVu(dv.getTenDichVu());
                    cthdCLS.setLoaiDichVu("CanLamSang");
                    cthdCLS.setDonGia(dv.getDonGia());
                    cthdCLS.setSoLuong(1);
                    billItems.add(cthdCLS);

                    totalSum = totalSum.add(dv.getDonGia());
                }
            }
        }

        boolean hasBHYT = benhNhanRepository.findById(pk.getMaBenhNhan())
                .map(b -> b.getMaBHYT() != null && !b.getMaBHYT().trim().isEmpty())
                .orElse(false);
        BigDecimal bhytTien = hasBHYT ? totalSum.multiply(BigDecimal.valueOf(0.8)) : BigDecimal.ZERO;

        HoaDon hd = new HoaDon();
        hd.setMaHoaDon(maHD);
        hd.setMaBenhNhan(pk.getMaBenhNhan());
        hd.setMaPhieuKham(maPK);
        hd.setNgayLap(LocalDateTime.now());
        hd.setTongTienDichVu(totalSum);
        hd.setBhytChiTra(bhytTien);
        hd.setHinhThucThanhToan("TienMat");
        hd.setTrangThaiTT("ChuaThanhToan");
        hd.setNhanVienThu("NV-CAS01");
        hoaDonRepository.save(hd);

        for (ChiTietHoaDon item : billItems) {
            chiTietHoaDonRepository.save(item);
        }

        ketQuaCLSRepository.saveAll(clsOrders);

        Map<String, Object> resp = new HashMap<>();
        resp.put("success", true);
        resp.put("maPhieuKham", maPK);
        resp.put("maHoaDon", maHD);
        resp.put("tongTienThuoc", tongTienThuoc);
        resp.put("message", "Khám bệnh thành công! Đã tạo đơn thuốc và chuyển hóa đơn sang viện phí.");
        if (isClsPaused) {
            resp.put("warning", "Khoa Cận Lâm Sàng hiện đang tạm ngưng tiếp nhận. Các chỉ định xét nghiệm đã được lưu vào hàng đợi và sẽ được phòng Lab tiếp nhận ngay khi Khoa mở lại.");
        }
        return resp;
    }

    @Transactional
    public Map<String, Object> chiDinhCLS(Map<String, Object> payload, Long accountId) {
        Optional<NhanVien> doctorOpt = accountId == null ? Optional.empty()
                : nhanVienRepository.findByMaTaiKhoan(accountId)
                        .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
        if (doctorOpt.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }

        String rawLichHen = (String) payload.get("maLichHen");
        Optional<LichHen> appointmentOpt = rawLichHen == null ? Optional.empty() : lichHenRepository.findById(rawLichHen);
        if (appointmentOpt.isEmpty()
                || !doctorOpt.get().getMaNhanVien().equals(appointmentOpt.get().getMaBacSi())
                || "DaKham".equalsIgnoreCase(appointmentOpt.get().getTrangThai())) {
            throw new IllegalArgumentException("Lịch khám không hợp lệ, không thuộc bác sĩ hoặc đã hoàn tất.");
        }

        LichHen appointment = appointmentOpt.get();
        Optional<PhieuKham> existingPk = phieuKhamRepository.findByMaLichHen(appointment.getMaLichHen());
        if (existingPk.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy Phiếu khám. Vui lòng bấm Bắt đầu khám trước.");
        }
        PhieuKham pk = existingPk.get();
        String maPK = pk.getMaPhieuKham();

        pk.setNgayKham(LocalDateTime.now());
        pk.setTrieuChung((String) payload.get("trieuChung"));
        pk.setChanDoan((String) payload.getOrDefault("chanDoan", "Chờ kết quả xét nghiệm"));

        if (payload.get("mach") != null) pk.setMach(Integer.parseInt(payload.get("mach").toString()));
        if (payload.get("nhietDo") != null) pk.setNhietDo(new BigDecimal(payload.get("nhietDo").toString()));
        if (payload.get("huyetAp") != null) pk.setHuyetAp((String) payload.get("huyetAp"));
        if (payload.get("nhipTho") != null) pk.setNhipTho(Integer.parseInt(payload.get("nhipTho").toString()));

        phieuKhamRepository.save(pk);

        if (pk.getMaLichHen() != null) {
            lichHenRepository.findById(pk.getMaLichHen()).ifPresent(lh -> {
                lh.setTrangThai("ChoKetQuaCLS");
                lichHenRepository.save(lh);
            });
        }

        boolean isClsPaused = false;
        List<KetQuaCLS> clsOrders = new ArrayList<>();
        List<?> clsList = (List<?>) payload.get("clsList");
        if (clsList != null && !clsList.isEmpty()) {
            // Kiểm tra nếu Khoa CLS đang tạm ngưng (TrangThai = 0 hoặc false)
            Optional<Khoa> clsDept = khoaRepository.findById("CLS");
            if (clsDept.isPresent() && Boolean.FALSE.equals(clsDept.get().getTrangThai())) {
                isClsPaused = true;
            }

            int clsSeq = 1;
            for (Object item : clsList) {
                String maDV = null;
                if (item instanceof String s) {
                    maDV = s;
                } else if (item instanceof Map<?, ?> m) {
                    maDV = (String) m.get("maDichVu");
                }
                if (maDV == null || maDV.trim().isEmpty()) continue;

                final int currentSeq = clsSeq++;
                final String finalMaDV = maDV;
                Optional<DichVuCLS> dvOpt = dichVuCLSRepository.findById(finalMaDV);
                if (dvOpt.isPresent()) {
                    DichVuCLS dv = dvOpt.get();
                    String maKQ = "CLS" + (System.currentTimeMillis() % 1000000) + "_" + currentSeq;
                    KetQuaCLS kq = new KetQuaCLS();
                    kq.setMaKetQua(maKQ);
                    kq.setMaPhieuKham(maPK);
                    kq.setMaBenhNhan(pk.getMaBenhNhan());
                    kq.setMaDichVu(finalMaDV);
                    kq.setMaKTV("NV-LAB01");
                    kq.setMaBacSiDoc(pk.getMaBacSi());
                    kq.setLoaiXetNghiem(dv.getTenDichVu());
                    kq.setNgayThucHien(LocalDateTime.now());
                    clsOrders.add(kq);
                }
            }
            ketQuaCLSRepository.saveAll(clsOrders);
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("success", true);
        resp.put("maPhieuKham", maPK);
        resp.put("message", "Chỉ định cận lâm sàng thành công. Bệnh nhân chuyển sang trạng thái Chờ kết quả.");
        if (isClsPaused) {
            resp.put("warning", "Khoa Cận Lâm Sàng hiện đang tạm ngưng tiếp nhận. Chỉ định đã được lưu vào hàng đợi và sẽ được thực hiện khi Khoa mở lại.");
        }
        return resp;
    }
}
