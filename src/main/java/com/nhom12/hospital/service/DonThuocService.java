package com.nhom12.hospital.service;

import com.nhom12.hospital.entity.DonThuoc;
import com.nhom12.hospital.entity.Thuoc;
import com.nhom12.hospital.entity.ChiTietNhapKho;
import com.nhom12.hospital.repository.BenhNhanRepository;
import com.nhom12.hospital.repository.DonThuocRepository;
import com.nhom12.hospital.repository.NhanVienRepository;
import com.nhom12.hospital.repository.PhieuKhamRepository;
import com.nhom12.hospital.repository.ThuocRepository;
import com.nhom12.hospital.repository.ChiTietNhapKhoRepository;
import com.nhom12.hospital.repository.HoaDonRepository;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class DonThuocService {

    private final DonThuocRepository donThuocRepository;
    private final PhieuKhamRepository phieuKhamRepository;
    private final ThuocRepository thuocRepository;
    private final BenhNhanRepository benhNhanRepository;
    private final NhanVienRepository nhanVienRepository;
    private final ChiTietNhapKhoRepository chiTietNhapKhoRepository;
    private final HoaDonRepository hoaDonRepository;

    public DonThuocService(DonThuocRepository donThuocRepository,
                           PhieuKhamRepository phieuKhamRepository,
                           ThuocRepository thuocRepository,
                           BenhNhanRepository benhNhanRepository,
                           NhanVienRepository nhanVienRepository,
                           ChiTietNhapKhoRepository chiTietNhapKhoRepository,
                           HoaDonRepository hoaDonRepository) {
        this.donThuocRepository = donThuocRepository;
        this.phieuKhamRepository = phieuKhamRepository;
        this.thuocRepository = thuocRepository;
        this.benhNhanRepository = benhNhanRepository;
        this.nhanVienRepository = nhanVienRepository;
        this.chiTietNhapKhoRepository = chiTietNhapKhoRepository;
        this.hoaDonRepository = hoaDonRepository;
    }

    public List<Map<String, Object>> getAll() {
        List<DonThuoc> list = donThuocRepository.findAll();
        List<Map<String, Object>> res = new ArrayList<>();

        for (DonThuoc dt : list) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", dt.getMaDonThuoc());
            map.put("maPhieuKham", dt.getMaPhieuKham());
            map.put("drugId", dt.getMaThuoc());
            map.put("qty", dt.getSoLuong());
            map.put("lieuDung", dt.getLieuDung());
            map.put("cachDung", dt.getCachDung());
            map.put("status", dt.getTrangThai());

            thuocRepository.findById(dt.getMaThuoc()).ifPresent(drug -> {
                map.put("drugName", drug.getTenThuoc());
                map.put("unit", drug.getDonViTinh());
                map.put("stock", drug.getTonKhoHienTai());
            });

            phieuKhamRepository.findById(dt.getMaPhieuKham()).ifPresent(pk -> {
                map.put("patientId", pk.getMaBenhNhan());
                benhNhanRepository.findById(pk.getMaBenhNhan()).ifPresent(bn -> {
                    map.put("patientName", bn.getHoTen());
                });
                nhanVienRepository.findById(pk.getMaBacSi()).ifPresent(nv -> {
                    map.put("doctor", nv.getHoTen());
                });
            });

            if (dt.getMaPhieuKham() != null) {
                map.put("tongTienThuocPhieuKham", donThuocRepository.tinhTongTienThuocTheoPhieuKham(dt.getMaPhieuKham()));
                hoaDonRepository.findByMaPhieuKham(dt.getMaPhieuKham()).ifPresent(hd -> {
                    map.put("paymentStatus", hd.getTrangThaiTT());
                    map.put("invoiceId", hd.getMaHoaDon());
                });
            }

            res.add(map);
        }
        return res;
    }

    @Transactional
    public Map<String, Object> xuatThuoc(String id) {
        Optional<DonThuoc> dtOpt = donThuocRepository.findById(id);
        if (dtOpt.isEmpty()) {
            throw new NoSuchElementException("Không tìm thấy đơn thuốc!");
        }
        DonThuoc dt = dtOpt.get();
        if ("DISPENSED".equalsIgnoreCase(dt.getTrangThai())) {
            throw new IllegalStateException("Thuốc này đã được cấp phát rồi!");
        }

        Optional<Thuoc> drugOpt = thuocRepository.findById(dt.getMaThuoc());
        if (drugOpt.isEmpty()) {
            throw new IllegalArgumentException("Thuốc không tồn tại!");
        }
        Thuoc drug = drugOpt.get();
        if (drug.getTonKhoHienTai() < dt.getSoLuong()) {
            throw new IllegalStateException("Số lượng tồn kho không đủ để xuất!");
        }

        // Cập nhật trạng thái đơn thuốc trước để kích hoạt Trigger SQL trg_KiemTraThanhToanTruocKhiPhatThuoc
        try {
            dt.setTrangThai("DISPENSED");
            donThuocRepository.save(dt);
        } catch (DataAccessException e) {
            Throwable cause = e.getMostSpecificCause();
            String msg = cause != null && cause.getMessage() != null ? cause.getMessage() : e.getMessage();
            throw new IllegalStateException(msg);
        }

        // Thực hiện FEFO
        int remainingToDispense = dt.getSoLuong();
        List<ChiTietNhapKho> batches = chiTietNhapKhoRepository.findByMaThuocForFEFO(dt.getMaThuoc());
        for (ChiTietNhapKho batch : batches) {
            if (remainingToDispense <= 0) break;

            int batchStock = batch.getSoLuongTon();
            if (batchStock >= remainingToDispense) {
                batch.setSoLuongTon(batchStock - remainingToDispense);
                chiTietNhapKhoRepository.save(batch);
                remainingToDispense = 0;
            } else {
                batch.setSoLuongTon(0);
                chiTietNhapKhoRepository.save(batch);
                remainingToDispense -= batchStock;
            }
        }

        drug.setTonKhoHienTai(drug.getTonKhoHienTai() - dt.getSoLuong());
        thuocRepository.save(drug);

        return Map.of("success", true, "message", "Đã xuất thuốc thành công!", "tonKhoMoi", drug.getTonKhoHienTai());
    }
}
