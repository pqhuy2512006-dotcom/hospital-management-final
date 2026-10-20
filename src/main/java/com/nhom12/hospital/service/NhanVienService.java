package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.NhanVien;
import com.nhom12.hospital.entity.TaiKhoan;
import com.nhom12.hospital.repository.NhanVienRepository;
import com.nhom12.hospital.repository.TaiKhoanRepository;
import com.nhom12.hospital.repository.PhanCongRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class NhanVienService {

    private final NhanVienRepository nhanVienRepository;
    private final TaiKhoanRepository taiKhoanRepository;
    private final PhanCongRepository phanCongRepository;

    public NhanVienService(NhanVienRepository nhanVienRepository, 
                           TaiKhoanRepository taiKhoanRepository,
                           PhanCongRepository phanCongRepository) {
        this.nhanVienRepository = nhanVienRepository;
        this.taiKhoanRepository = taiKhoanRepository;
        this.phanCongRepository = phanCongRepository;
    }

    public List<NhanVien> getAll() {
        return nhanVienRepository.findAll();
    }

    public Optional<NhanVien> getById(String id) {
        return nhanVienRepository.findById(id);
    }

    public Optional<NhanVien> findByAccountId(Long accountId) {
        return accountId == null ? Optional.empty() : nhanVienRepository.findByMaTaiKhoan(accountId);
    }

    public List<Map<String, String>> getDoctorsForConsultation() {
        return nhanVienRepository.findAll().stream()
                .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()))
                .filter(employee -> !"DaNghi".equalsIgnoreCase(employee.getTrangThai()))
                .map(employee -> {
                    Map<String, String> doctor = new LinkedHashMap<>();
                    doctor.put("id", employee.getMaNhanVien());
                    doctor.put("name", employee.getHoTen());
                    doctor.put("specialty", employee.getMaKhoa());
                    doctor.put("maPhong", employee.getMaPhong());
                    return doctor;
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public NhanVien updateMyProfile(Long accountId, Map<String, String> payload) {
        Optional<NhanVien> employeeOpt = findByAccountId(accountId);
        if (employeeOpt.isEmpty()) {
            return null;
        }

        NhanVien employee = employeeOpt.get();
        String phone = payload.get("soDienThoai");
        if (phone == null || phone.trim().isEmpty()) {
            throw new IllegalArgumentException("Số điện thoại không được để trống.");
        }
        phone = phone.trim();
        if (nhanVienRepository.existsBySoDienThoaiAndMaNhanVienNot(phone, employee.getMaNhanVien())) {
            throw new IllegalArgumentException("Số điện thoại đã được nhân viên khác sử dụng.");
        }

        Optional<TaiKhoan> accountOpt = taiKhoanRepository.findById(accountId);
        if (accountOpt.isEmpty()) {
            return null;
        }

        String email = normalizeOptional(payload.get("email"));
        if (email != null && taiKhoanRepository.findByEmail(email)
                .filter(account -> !account.getMaTaiKhoan().equals(accountId)).isPresent()) {
            throw new IllegalArgumentException("Email đã được tài khoản khác sử dụng.");
        }

        employee.setSoDienThoai(phone);
        employee.setEmail(email);
        employee.setMaPhong(normalizeOptional(payload.get("maPhong")));
        nhanVienRepository.save(employee);

        TaiKhoan account = accountOpt.get();
        account.setEmail(email);
        taiKhoanRepository.save(account);

        return employee;
    }

    public NhanVien create(NhanVien nhanVien) {
        if (nhanVien.getMaNhanVien() == null || nhanVien.getMaNhanVien().trim().isEmpty()) {
            nhanVien.setMaNhanVien("NV-DOC" + String.format("%02d", nhanVienRepository.count() + 1));
        }
        if (nhanVien.getSoDienThoai() != null) {
            boolean sdtExists = nhanVienRepository.findAll().stream()
                    .anyMatch(nv -> nhanVien.getSoDienThoai().equals(nv.getSoDienThoai()));
            if (sdtExists) {
                throw new IllegalArgumentException("Số điện thoại " + nhanVien.getSoDienThoai() + " đã được đăng ký cho nhân viên khác!");
            }
        }
                if (nhanVien.getVaiTro() == null) {
            nhanVien.setVaiTro("BacSi");
        } else if ("NhanSu".equalsIgnoreCase(nhanVien.getVaiTro())) {
            nhanVien.setVaiTro("QuanLyNhanSu");
        }
        if (nhanVien.getTrangThai() == null) {
            nhanVien.setTrangThai("DangLamViec");
        }
        
        // Auto-link Account by Phone Number or Email
        if (nhanVien.getMaTaiKhoan() == null) {
            if (nhanVien.getSoDienThoai() != null && !nhanVien.getSoDienThoai().trim().isEmpty()) {
                taiKhoanRepository.findBySoDienThoai(nhanVien.getSoDienThoai())
                        .ifPresent(tk -> nhanVien.setMaTaiKhoan(tk.getMaTaiKhoan()));
                if (nhanVien.getMaTaiKhoan() == null) {
                    taiKhoanRepository.findByTenDangNhap(nhanVien.getSoDienThoai())
                            .ifPresent(tk -> nhanVien.setMaTaiKhoan(tk.getMaTaiKhoan()));
                }
            }
            if (nhanVien.getMaTaiKhoan() == null && nhanVien.getEmail() != null && !nhanVien.getEmail().trim().isEmpty()) {
                taiKhoanRepository.findByEmail(nhanVien.getEmail())
                        .ifPresent(tk -> nhanVien.setMaTaiKhoan(tk.getMaTaiKhoan()));
            }
        }

        NhanVien saved = nhanVienRepository.save(nhanVien);
        if (saved.getMaKhoa() != null && !saved.getMaKhoa().trim().isEmpty()) {
            String chucVu = (saved.getTrinhDoChuyenMon() != null && !saved.getTrinhDoChuyenMon().trim().isEmpty())
                    ? saved.getTrinhDoChuyenMon()
                    : saved.getVaiTro();
            phanCongRepository.themPhanCongMoi(saved.getMaNhanVien(), saved.getMaKhoa(), chucVu, LocalDate.now(), "Phân công công tác ban đầu");
        }
        return saved;
    }

    public Optional<NhanVien> update(String id, NhanVien updated) {
        return nhanVienRepository.findById(id).map(nv -> {
            if (updated.getSoDienThoai() != null && nhanVienRepository.existsBySoDienThoaiAndMaNhanVienNot(updated.getSoDienThoai(), id)) {
                throw new IllegalArgumentException("Số điện thoại đã được nhân viên khác sử dụng.");
            }
            nv.setHoTen(updated.getHoTen());
            nv.setTrinhDoChuyenMon(updated.getTrinhDoChuyenMon());
            nv.setMaKhoa(updated.getMaKhoa());
            nv.setMaPhong(updated.getMaPhong());;
            nv.setSoDienThoai(updated.getSoDienThoai());
            nv.setChungChiHanhNghe(updated.getChungChiHanhNghe());
            nv.setTrangThai(updated.getTrangThai());
            nv.setVaiTro(updated.getVaiTro());
            return nhanVienRepository.save(nv);
        });
    }

    public Map<String, Object> profileView(NhanVien employee) {
        Map<String, Object> profile = new LinkedHashMap<>();
        profile.put("maNhanVien", employee.getMaNhanVien());
        profile.put("hoTen", employee.getHoTen());
        profile.put("vaiTro", employee.getVaiTro());
        profile.put("chuyenKhoa", employee.getMaKhoa());
        profile.put("chungChiHanhNghe", employee.getChungChiHanhNghe());
        profile.put("soDienThoai", employee.getSoDienThoai());
        profile.put("email", employee.getEmail());
        profile.put("maPhong", employee.getMaPhong());
        profile.put("maKhoa", employee.getMaKhoa());
        return profile;
    }

    private String normalizeOptional(String value) {
        return value == null || value.trim().isEmpty() ? null : value.trim();
    }
}




