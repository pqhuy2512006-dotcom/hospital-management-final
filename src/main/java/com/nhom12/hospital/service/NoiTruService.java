package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.NoiTru;
import com.nhom12.hospital.repository.BenhNhanRepository;
import com.nhom12.hospital.repository.GiuongBenhRepository;
import com.nhom12.hospital.repository.NoiTruRepository;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.nhom12.hospital.entity.BenhNhan;
import com.nhom12.hospital.entity.GiuongBenh;
import com.nhom12.hospital.entity.Khoa;
import com.nhom12.hospital.entity.NhanVien;
import com.nhom12.hospital.entity.PhieuKham;
import com.nhom12.hospital.entity.YeuCauChuyenKhoa;
import com.nhom12.hospital.repository.KhoaRepository;
import com.nhom12.hospital.repository.NhanVienRepository;
import com.nhom12.hospital.repository.PhieuKhamRepository;
import com.nhom12.hospital.repository.YeuCauChuyenKhoaRepository;
import com.nhom12.hospital.entity.Phong;
import com.nhom12.hospital.repository.PhongRepository;
import com.nhom12.hospital.entity.HoaDon;
import com.nhom12.hospital.entity.ChiTietHoaDon;
import com.nhom12.hospital.repository.HoaDonRepository;
import com.nhom12.hospital.repository.ChiTietHoaDonRepository;
import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class NoiTruService {
    private final NoiTruRepository noiTruRepository;
    private final BenhNhanRepository benhNhanRepository;
    private final GiuongBenhRepository giuongBenhRepository;
    private final NhanVienRepository nhanVienRepository;
    private final PhieuKhamRepository phieuKhamRepository;
    private final KhoaRepository khoaRepository;
    private final YeuCauChuyenKhoaRepository yeuCauChuyenKhoaRepository;
    private final PhongRepository phongRepository;
    private final HoaDonRepository hoaDonRepository;
    private final ChiTietHoaDonRepository chiTietHoaDonRepository;

    public NoiTruService(NoiTruRepository noiTruRepository,
                         BenhNhanRepository benhNhanRepository,
                         GiuongBenhRepository giuongBenhRepository,
                         NhanVienRepository nhanVienRepository,
                         PhieuKhamRepository phieuKhamRepository,
                         KhoaRepository khoaRepository,
                         YeuCauChuyenKhoaRepository yeuCauChuyenKhoaRepository,
                         PhongRepository phongRepository,
                         HoaDonRepository hoaDonRepository,
                         ChiTietHoaDonRepository chiTietHoaDonRepository) {
        this.noiTruRepository = noiTruRepository;
        this.benhNhanRepository = benhNhanRepository;
        this.giuongBenhRepository = giuongBenhRepository;
        this.nhanVienRepository = nhanVienRepository;
        this.phieuKhamRepository = phieuKhamRepository;
        this.khoaRepository = khoaRepository;
        this.yeuCauChuyenKhoaRepository = yeuCauChuyenKhoaRepository;
        this.phongRepository = phongRepository;
        this.hoaDonRepository = hoaDonRepository;
        this.chiTietHoaDonRepository = chiTietHoaDonRepository;
    }

    public List<Map<String, Object>> getAll() {
        List<NoiTru> list = noiTruRepository.findAll();
        List<Map<String, Object>> res = new ArrayList<>();
        for (NoiTru nt : list) {
            Map<String, Object> map = new HashMap<>();
            map.put("maNoiTru", nt.getMaNoiTru());
            map.put("maBenhNhan", nt.getMaBenhNhan());
            map.put("maGiuong", nt.getMaGiuong());
            map.put("maPhieuKham", nt.getMaPhieuKham());
            map.put("ngayNhapVien", nt.getNgayNhapVien());
            map.put("ngayXuatVien", nt.getNgayXuatVien());
            map.put("trangThai", nt.getTrangThai());

            benhNhanRepository.findById(nt.getMaBenhNhan()).ifPresent(bn -> {
                map.put("tenBenhNhan", bn.getHoTen());
                map.put("gioiTinh", bn.getGioiTinh());
                map.put("ngaySinh", bn.getNgaySinh());
                map.put("maBHYT", bn.getMaBHYT());
                map.put("soDienThoai", bn.getSoDienThoai());
            });

            giuongBenhRepository.findById(nt.getMaGiuong()).ifPresent(g -> {
                map.put("soGiuong", g.getSoGiuong());
                map.put("maKhoa", g.getMaKhoa());
                map.put("donGiaNgay", g.getDonGiaNgay());
            });

            res.add(map);
        }
        return res;
    }

    public NoiTru nhapVien(NoiTru noiTru) {
        return nhapVien(noiTru, null);
    }

    public NoiTru nhapVien(NoiTru noiTru, Long accountId) {
        if (noiTru.getMaBenhNhan() == null || noiTru.getMaBenhNhan().trim().isEmpty()) {
            throw new IllegalArgumentException("Vui lòng nhập mã bệnh nhân.");
        }
        String maBn = noiTru.getMaBenhNhan().trim();
        noiTru.setMaBenhNhan(maBn);

        BenhNhan bn = benhNhanRepository.findById(maBn)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bệnh nhân có mã: " + maBn));

        if (noiTru.getMaGiuong() == null || noiTru.getMaGiuong().trim().isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn giường bệnh.");
        }
        GiuongBenh giuong = giuongBenhRepository.findById(noiTru.getMaGiuong())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giường bệnh: " + noiTru.getMaGiuong()));

        if ("BaoTri".equalsIgnoreCase(giuong.getTrangThai())) {
            throw new IllegalArgumentException("Giường " + giuong.getSoGiuong() + " hiện đang bảo trì.");
        }
        if (giuong.getMaPhong() != null) {
            Optional<Phong> phongOpt = phongRepository.findById(giuong.getMaPhong());
            if (phongOpt.isPresent() && Boolean.FALSE.equals(phongOpt.get().getTrangThai())) {
                String tenPhong = phongOpt.get().getTenPhong() != null ? phongOpt.get().getTenPhong() : phongOpt.get().getMaPhong();
                throw new IllegalArgumentException("Phòng " + tenPhong + " hiện đang tạm ngưng / sửa chữa. Không thể xếp bệnh nhân vào giường trong phòng này.");
            }
        }
        // 1. Kiểm tra bệnh nhân có đang nằm giường khác hay không
        Optional<NoiTru> activeStay = noiTruRepository.findActiveByMaBenhNhan(maBn);
        if (activeStay.isPresent()) {
            throw new IllegalArgumentException("Bệnh nhân " + bn.getHoTen() + " hiện đang nằm điều trị tại giường "
                    + activeStay.get().getMaGiuong() + ". Không thể xếp thêm giường mới.");
        }

        // 2. Kiểm tra quyền hạn khoa của Điều dưỡng
        if (accountId != null) {
            Optional<NhanVien> currentStaff = nhanVienRepository.findByMaTaiKhoan(accountId);
            if (currentStaff.isPresent()) {
                NhanVien nv = currentStaff.get();
                if ("DieuDuong".equalsIgnoreCase(nv.getVaiTro()) && nv.getMaKhoa() != null) {
                    if (!nv.getMaKhoa().equalsIgnoreCase(giuong.getMaKhoa())) {
                        String tenKhoaNv = khoaRepository.findById(nv.getMaKhoa()).map(Khoa::getTenKhoa).orElse(nv.getMaKhoa());
                        throw new IllegalArgumentException("Bạn chỉ có quyền xếp giường thuộc khoa của mình (" + tenKhoaNv + ").");
                    }
                }
            }
        }

        // 3. Kiểm tra bệnh nhân có thuộc khoa của giường này hay không
        String maKhoaGiuong = giuong.getMaKhoa();
        List<PhieuKham> phieuKhams = phieuKhamRepository.findByMaBenhNhan(maBn);
        PhieuKham latestPk = phieuKhams.isEmpty() ? null : phieuKhams.get(0);

        String maPhieuKhamHopLe = null;

        if (latestPk != null && maKhoaGiuong != null && maKhoaGiuong.equalsIgnoreCase(latestPk.getMaKhoa())) {
            maPhieuKhamHopLe = latestPk.getMaPhieuKham();
        } else {
            // Nếu phiếu khám gần nhất ở khoa khác, kiểm tra xem có yêu cầu chuyển khoa đến khoa này đã được duyệt chưa
            Optional<YeuCauChuyenKhoa> approvedTransfer = yeuCauChuyenKhoaRepository.findLatestApprovedTransfer(maBn, maKhoaGiuong);
            if (approvedTransfer.isPresent()) {
                YeuCauChuyenKhoa yc = approvedTransfer.get();
                maPhieuKhamHopLe = yc.getMaPhieuKham();
                if ("CHO_XEP_GIUONG".equalsIgnoreCase(yc.getTrangThai())) {
                    yc.setTrangThai("DA_TIEP_NHAN");
                    yeuCauChuyenKhoaRepository.save(yc);
                }
            } else {
                String tenKhoaGiuong = khoaRepository.findById(maKhoaGiuong).map(Khoa::getTenKhoa).orElse(maKhoaGiuong);
                if (latestPk == null) {
                    throw new IllegalArgumentException("Bệnh nhân " + bn.getHoTen() + " (" + maBn + ") chưa có phiếu khám bệnh nào tại bệnh viện.");
                } else {
                    String tenKhoaKham = khoaRepository.findById(latestPk.getMaKhoa()).map(Khoa::getTenKhoa).orElse(latestPk.getMaKhoa());
                    throw new IllegalArgumentException("Bệnh nhân " + bn.getHoTen() + " (" + maBn + ") hiện thuộc " + tenKhoaKham
                            + " (Phiếu khám: " + latestPk.getMaPhieuKham() + "). Không thể xếp vào "
                            + tenKhoaGiuong + " khi chưa có yêu cầu chuyển khoa được duyệt.");
                }
            }
        }

        if (noiTru.getMaNoiTru() == null || noiTru.getMaNoiTru().trim().isEmpty()) {
            noiTru.setMaNoiTru("NT" + System.currentTimeMillis() % 10000000);
        }
        if (noiTru.getNgayNhapVien() == null) {
            noiTru.setNgayNhapVien(LocalDateTime.now());
        }
        if (noiTru.getTrangThai() == null) {
            noiTru.setTrangThai("DangNam");
        }
        noiTru.setMaPhieuKham(maPhieuKhamHopLe);

        // Để Trigger SQL TRG_CapNhatTrangThaiGiuong tự động kiểm tra trùng giường và cập nhật trạng thái giường sang 'DangSuDung'
        try {
            return noiTruRepository.save(noiTru);
        } catch (DataAccessException e) {
            Throwable cause = e.getMostSpecificCause();
            String msg = cause != null && cause.getMessage() != null ? cause.getMessage() : e.getMessage();
            throw new IllegalStateException(msg);
        }
    }

    public Optional<Map<String, Object>> xuatVien(String id) {
        return noiTruRepository.findById(id).map(nt -> {
            LocalDateTime now = LocalDateTime.now();
            nt.setTrangThai("DaXuatVien");
            nt.setNgayXuatVien(now);
            // Trigger SQL TRG_CapNhatTrangThaiGiuong sẽ tự động trả trạng thái giường về 'Trong'
            noiTruRepository.save(nt);

            // 1. Tính số ngày nằm viện (tối thiểu 1 ngày)
            long soNgay = 1;
            if (nt.getNgayNhapVien() != null) {
                soNgay = ChronoUnit.DAYS.between(nt.getNgayNhapVien().toLocalDate(), now.toLocalDate());
                if (soNgay <= 0) soNgay = 1;
            }

            // 2. Lấy đơn giá giường từ GiuongBenh
            BigDecimal donGiaNgay = BigDecimal.valueOf(300000); // Mặc định nếu chưa set
            Optional<GiuongBenh> giuongOpt = giuongBenhRepository.findById(nt.getMaGiuong());
            if (giuongOpt.isPresent()) {
                GiuongBenh g = giuongOpt.get();
                if (g.getDonGiaNgay() != null && g.getDonGiaNgay().compareTo(BigDecimal.ZERO) > 0) {
                    donGiaNgay = g.getDonGiaNgay();
                }
            }

            // 3. Tính tiền và áp dụng BHYT
            BigDecimal tongTienGiuong = donGiaNgay.multiply(BigDecimal.valueOf(soNgay));
            boolean hasBHYT = benhNhanRepository.findById(nt.getMaBenhNhan())
                    .map(b -> b.getMaBHYT() != null && !b.getMaBHYT().trim().isEmpty())
                    .orElse(false);
            BigDecimal bhytChiTra = hasBHYT ? tongTienGiuong.multiply(BigDecimal.valueOf(0.8)) : BigDecimal.ZERO;
            BigDecimal soTienPhaiNop = tongTienGiuong.subtract(bhytChiTra);

            // 4. Tự động sinh Hóa đơn viện phí nội trú
            String maHD = "HD" + (System.currentTimeMillis() % 10000000);
            HoaDon hd = new HoaDon();
            hd.setMaHoaDon(maHD);
            hd.setMaBenhNhan(nt.getMaBenhNhan());
            hd.setMaPhieuKham(nt.getMaPhieuKham() != null ? nt.getMaPhieuKham() : "PK" + (System.currentTimeMillis() % 1000000));
            hd.setNgayLap(now);
            hd.setTongTienDichVu(tongTienGiuong);
            hd.setBhytChiTra(bhytChiTra);
            hd.setHinhThucThanhToan("TienMat");
            hd.setTrangThaiTT("ChuaThanhToan");
            hd.setNhanVienThu("NV-CAS01");
            hoaDonRepository.save(hd);

            // 5. Thêm chi tiết tiền giường vào ChiTietHoaDon (Loại dịch vụ chuẩn: 'Giuong')
            ChiTietHoaDon cthd = new ChiTietHoaDon();
            cthd.setMaChiTietHD("CTHD" + (System.currentTimeMillis() % 1000000) + "_BED");
            cthd.setMaHoaDon(maHD);
            cthd.setTenDichVu("Tiền giường nội trú (" + soNgay + " ngày)");
            cthd.setLoaiDichVu("Giuong");
            cthd.setDonGia(donGiaNgay);
            cthd.setSoLuong((int) soNgay);
            chiTietHoaDonRepository.save(cthd);

            Map<String, Object> resp = new HashMap<>();
            resp.put("noiTru", nt);
            resp.put("maHoaDon", maHD);
            resp.put("soNgay", soNgay);
            resp.put("donGiaNgay", donGiaNgay);
            resp.put("tongTien", tongTienGiuong);
            resp.put("bhytChiTra", bhytChiTra);
            resp.put("soTienPhaiNop", soTienPhaiNop);
            resp.put("message", "Xuất viện thành công và đã chuyển hóa đơn tiền giường sang Thu ngân!");
            return resp;
        });
    }
}
