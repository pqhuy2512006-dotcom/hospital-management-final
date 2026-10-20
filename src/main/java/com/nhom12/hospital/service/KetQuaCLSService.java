package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.ChiTietKetQuaCLS;
import com.nhom12.hospital.entity.KetQuaCLS;
import com.nhom12.hospital.entity.NhanVien;
import com.nhom12.hospital.repository.BenhNhanRepository;
import com.nhom12.hospital.repository.ChiTietKetQuaCLSRepository;
import com.nhom12.hospital.repository.KetQuaCLSRepository;
import com.nhom12.hospital.repository.NhanVienRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class KetQuaCLSService {

    private final KetQuaCLSRepository ketQuaCLSRepository;
    private final ChiTietKetQuaCLSRepository chiTietKetQuaCLSRepository;
    private final BenhNhanRepository benhNhanRepository;
    private final NhanVienRepository nhanVienRepository;

    public KetQuaCLSService(KetQuaCLSRepository ketQuaCLSRepository,
                            ChiTietKetQuaCLSRepository chiTietKetQuaCLSRepository,
                            BenhNhanRepository benhNhanRepository,
                            NhanVienRepository nhanVienRepository) {
        this.ketQuaCLSRepository = ketQuaCLSRepository;
        this.chiTietKetQuaCLSRepository = chiTietKetQuaCLSRepository;
        this.benhNhanRepository = benhNhanRepository;
        this.nhanVienRepository = nhanVienRepository;
    }

    public List<Map<String, Object>> getAll() {
        return mapResults(ketQuaCLSRepository.findAll());
    }

    public List<Map<String, Object>> getMyResults(Long accountId) {
        if (accountId == null) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }
        Optional<NhanVien> doctor = nhanVienRepository.findByMaTaiKhoan(accountId)
                .filter(employee -> "BacSi".equalsIgnoreCase(employee.getVaiTro()));
        if (doctor.isEmpty()) {
            throw new IllegalStateException("Không tìm thấy hồ sơ bác sĩ.");
        }
        return mapResults(ketQuaCLSRepository.findByMaBacSiDoc(doctor.get().getMaNhanVien()));
    }

        private List<Map<String, Object>> mapResults(List<KetQuaCLS> list) {
        List<Map<String, Object>> res = new ArrayList<>();

        for (KetQuaCLS kq : list) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", kq.getMaKetQua());
            map.put("patientId", kq.getMaBenhNhan());
            map.put("examId", kq.getMaPhieuKham());
            map.put("service", kq.getLoaiXetNghiem());
            map.put("serviceCode", kq.getMaDichVu());
            map.put("conclusion", kq.getKetLuan());
            map.put("hinhAnhFile", kq.getHinhAnhFile());
            map.put("status", kq.getKetLuan() != null && !kq.getKetLuan().trim().isEmpty() ? "COMPLETED" : "PENDING");
            map.put("dept", "Khoa Cận Lâm Sàng");

            benhNhanRepository.findById(kq.getMaBenhNhan()).ifPresent(bn -> {
                map.put("patientName", bn.getHoTen());
            });

            nhanVienRepository.findById(kq.getMaBacSiDoc() != null ? kq.getMaBacSiDoc() : kq.getMaKTV()).ifPresent(nv -> {
                map.put("doctor", nv.getHoTen());
            });

            List<ChiTietKetQuaCLS> details = chiTietKetQuaCLSRepository.findByMaKetQua(kq.getMaKetQua());
            List<Map<String, Object>> params = new ArrayList<>();

            // 👉 NẾU PHIẾU CHƯA CÓ CHỈ SỐ: TỰ ĐỘNG SINH DANH MỤC MẪU THEO TÊN DỊCH VỤ
            if (details.isEmpty()) {
                params = getTemplateParams(kq.getLoaiXetNghiem());
            } else {
                for (ChiTietKetQuaCLS d : details) {
                    Map<String, Object> p = new HashMap<>();
                    p.put("name", d.getTenChiSo());
                    p.put("val", d.getGiaTri());
                    p.put("unit", d.getDonVi());
                    p.put("ref", d.getKhoangThamChieu());
                    p.put("eval", d.getDanhGia());

                    // parse refMin/refMax nếu có dạng "min - max"
                    if (d.getKhoangThamChieu() != null && d.getKhoangThamChieu().contains("-")) {
                        String[] parts = d.getKhoangThamChieu().split("-");
                        try {
                            p.put("refMin", Double.parseDouble(parts[0].replaceAll("[^0-9.]", "").trim()));
                            p.put("refMax", Double.parseDouble(parts[1].replaceAll("[^0-9.]", "").trim()));
                        } catch (Exception ignored) {
                            p.put("refMin", null);
                            p.put("refMax", null);
                        }
                    } else {
                        p.put("refMin", null);
                        p.put("refMax", null);
                    }
                    params.add(p);
                }
            }
            map.put("params", params);
            res.add(map);
        }

        return res;
    }

    private List<Map<String, Object>> getTemplateParams(String loaiXetNghiem) {
        List<Map<String, Object>> params = new ArrayList<>();
        String name = loaiXetNghiem != null ? loaiXetNghiem.toLowerCase() : "";

        if (name.contains("glucose") || name.contains("đường huyết")) {
            params.add(buildParam("Định lượng Glucose", "", "mmol/L", "3.9 - 6.4", 3.9, 6.4, "BinhThuong"));
        } else if (name.contains("tế bào máu") || name.contains("huyết học")) {
            params.add(buildParam("Số lượng hồng cầu (RBC)", "", "T/L", "4.2 - 5.4", 4.2, 5.4, "BinhThuong"));
            params.add(buildParam("Huyết sắc tố (Hb)", "", "g/L", "130 - 160", 130.0, 160.0, "BinhThuong"));
            params.add(buildParam("Số lượng bạch cầu (WBC)", "", "G/L", "4.0 - 10.0", 4.0, 10.0, "BinhThuong"));
            params.add(buildParam("Số lượng tiểu cầu (PLT)", "", "G/L", "150 - 450", 150.0, 450.0, "BinhThuong"));
        } else if (name.contains("ure") || name.contains("urê")) {
            params.add(buildParam("Định lượng Ure", "", "mmol/L", "2.5 - 7.5", 2.5, 7.5, "BinhThuong"));
        } else if (name.contains("creatinin")) {
            params.add(buildParam("Định lượng Creatinine", "", "µmol/L", "62 - 115", 62.0, 115.0, "BinhThuong"));
        } else if (name.contains("men gan") || name.contains("ast") || name.contains("alt")) {
            params.add(buildParam("AST (GOT)", "", "U/L", "0 - 40", 0.0, 40.0, "BinhThuong"));
            params.add(buildParam("ALT (GPT)", "", "U/L", "0 - 40", 0.0, 40.0, "BinhThuong"));
        } else if (name.contains("cholesterol")) {
            params.add(buildParam("Cholesterol toàn phần", "", "mmol/L", "3.9 - 5.2", 3.9, 5.2, "BinhThuong"));
            params.add(buildParam("Triglyceride", "", "mmol/L", "0.4 - 1.8", 0.4, 1.8, "BinhThuong"));
        } else {
            params.add(buildParam(loaiXetNghiem != null ? loaiXetNghiem : "Chỉ số xét nghiệm", "", "Lần", "Bình thường", null, null, "BinhThuong"));
        }
        return params;
    }

    private Map<String, Object> buildParam(String name, String val, String unit, String ref, Double min, Double max, String eval) {
        Map<String, Object> p = new HashMap<>();
        p.put("name", name);
        p.put("val", val);
        p.put("unit", unit);
        p.put("ref", ref);
        p.put("refMin", min);
        p.put("refMax", max);
        p.put("eval", eval);
        return p;
    }

    @Transactional
    public Map<String, Object> capNhatKetQua(String id, Map<String, Object> payload) {
        Optional<KetQuaCLS> kqOpt = ketQuaCLSRepository.findById(id);
        if (kqOpt.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy kết quả cận lâm sàng!");
        }
        KetQuaCLS kq = kqOpt.get();
        String conclusion = (String) payload.get("conclusion");
        String hinhAnh = (String) payload.get("hinhAnh");
        kq.setKetLuan(conclusion);
        if (hinhAnh != null) kq.setHinhAnhFile(hinhAnh);
        ketQuaCLSRepository.save(kq);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> params = (List<Map<String, Object>>) payload.get("params");
        if (params != null) {
            int seq = 1;
            for (Map<String, Object> p : params) {
                String name = (String) p.get("name");
                String val = (String) p.get("val");
                String eval = (String) p.get("eval");

                // Chuẩn hóa theo ràng buộc CHECK (DanhGia IN ('BinhThuong','Cao','Thap'))
                if ("Tang".equalsIgnoreCase(eval)) eval = "Cao";
                if ("Giam".equalsIgnoreCase(eval)) eval = "Thap";
                if (!"Cao".equalsIgnoreCase(eval) && !"Thap".equalsIgnoreCase(eval)) {
                    eval = "BinhThuong";
                }

                List<ChiTietKetQuaCLS> details = chiTietKetQuaCLSRepository.findByMaKetQua(id);
                Optional<ChiTietKetQuaCLS> targetOpt = details.stream().filter(d -> d.getTenChiSo().equalsIgnoreCase(name)).findFirst();
                if (targetOpt.isPresent()) {
                    ChiTietKetQuaCLS target = targetOpt.get();
                    target.setGiaTri(val);
                    target.setDanhGia(eval);
                    chiTietKetQuaCLSRepository.save(target);
                } else {
                    ChiTietKetQuaCLS newDetail = new ChiTietKetQuaCLS();
                    newDetail.setMaChiTietXN(String.format("CT%06d_%d", System.currentTimeMillis() % 1000000, seq++));
                    newDetail.setMaKetQua(id);
                    newDetail.setTenChiSo(name);
                    newDetail.setGiaTri(val);
                    newDetail.setDonVi((String) p.getOrDefault("unit", ""));
                    newDetail.setKhoangThamChieu((String) p.getOrDefault("ref", ""));
                    newDetail.setDanhGia(eval);
                    chiTietKetQuaCLSRepository.save(newDetail);
                }
            }
        }
        return Map.of("success", true, "message", "Đã lưu và trả kết quả xét nghiệm thành công!");
    }
}


