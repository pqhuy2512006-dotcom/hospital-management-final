package com.nhom12.hospital.repository;

import com.nhom12.hospital.entity.DonThuoc;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class DonThuocRepository {

    private static final BeanPropertyRowMapper<DonThuoc> ROW_MAPPER =
            BeanPropertyRowMapper.newInstance(DonThuoc.class);

    private final JdbcTemplate jdbcTemplate;

    public DonThuocRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<DonThuoc> findAll() {
        return jdbcTemplate.query("SELECT * FROM dbo.vw_DonThuoc", ROW_MAPPER);
    }

    public Optional<DonThuoc> findById(String id) {
        return jdbcTemplate.query(
                "SELECT * FROM dbo.vw_DonThuoc WHERE MaDonThuoc = ?",
                ROW_MAPPER,
                id
        ).stream().findFirst();
    }

    public List<DonThuoc> findByMaPhieuKham(String maPhieuKham) {
        return jdbcTemplate.query(
                "SELECT * FROM dbo.vw_DonThuoc WHERE MaPhieuKham = ?",
                ROW_MAPPER,
                maPhieuKham
        );
    }

    public BigDecimal tinhTongTienThuocTheoPhieuKham(String maPhieuKham) {
        BigDecimal total = jdbcTemplate.queryForObject(
                "SELECT dbo.fn_TinhTongTienThuocTheoPhieuKham(?)",
                BigDecimal.class,
                maPhieuKham
        );
        return total != null ? total : BigDecimal.ZERO;
    }

    public DonThuoc save(DonThuoc prescription) {
        Map<String, Object> columns = new LinkedHashMap<>();
        columns.put("MaDonThuoc", prescription.getMaDonThuoc());
        columns.put("MaPhieuKham", prescription.getMaPhieuKham());
        columns.put("MaThuoc", prescription.getMaThuoc());
        columns.put("SoLo", prescription.getSoLo());
        columns.put("DonViTinh", prescription.getDonViTinh());
        columns.put("SoLuong", prescription.getSoLuong());
        columns.put("LieuDung", prescription.getLieuDung());
        columns.put("CachDung", prescription.getCachDung());
        columns.put("TrangThai", prescription.getTrangThai());
        EntityProcedureSupport.save(jdbcTemplate, "DonThuoc", columns);
        return prescription;
    }

    @Transactional
    public <S extends DonThuoc> List<S> saveAll(Iterable<S> prescriptions) {
        List<S> saved = new ArrayList<>();
        for (S prescription : prescriptions) {
            save(prescription);
            saved.add(prescription);
        }
        return saved;
    }

    public void deleteById(String id) {
        jdbcTemplate.update(
                "EXEC dbo.usp_Entity_Delete @EntityName = ?, @IdValue = ?",
                "DonThuoc",
                id
        );
    }
}
