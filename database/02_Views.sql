/* ======================================================================
   02_Views.sql - Views (27 Views)
   ====================================================================== */
USE [QuanLyBenhVien];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.vw_AuditLog AS SELECT * FROM dbo.AuditLog;
GO
CREATE OR ALTER VIEW dbo.vw_BenhNhan AS SELECT * FROM dbo.BenhNhan;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietHoaDon AS SELECT * FROM dbo.ChiTietHoaDon;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietKetQuaCLS AS SELECT * FROM dbo.ChiTietKetQuaCLS;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietNhapKho AS SELECT * FROM dbo.ChiTietNhapKho;
GO
CREATE OR ALTER VIEW dbo.vw_DichVuCLS AS SELECT * FROM dbo.DichVuCLS;
GO
CREATE OR ALTER VIEW dbo.vw_DonThuoc AS SELECT * FROM dbo.DonThuoc;
GO
CREATE OR ALTER VIEW dbo.vw_GiuongBenh AS
SELECT g.MaGiuong, g.MaPhong, g.SoGiuong, g.TrangThai, g.DonGiaNgay, p.TenPhong, p.MaKhoa
FROM dbo.GiuongBenh g LEFT JOIN dbo.Phong p ON g.MaPhong = p.MaPhong;
GO
CREATE OR ALTER VIEW dbo.vw_HoaDon AS SELECT * FROM dbo.HoaDon;
GO
CREATE OR ALTER VIEW dbo.vw_KetQuaCLS AS SELECT * FROM dbo.KetQuaCLS;
GO
CREATE OR ALTER VIEW dbo.vw_Khoa AS
SELECT k.MaKhoa, k.TenKhoa, k.MoTa, k.MaTruongKhoa, ISNULL(k.TrangThai, 1) AS TrangThai, nv.HoTen AS TenTruongKhoa
FROM dbo.Khoa k LEFT JOIN dbo.NhanVien nv ON k.MaTruongKhoa = nv.MaNhanVien;
GO
CREATE OR ALTER VIEW dbo.vw_LichHen AS SELECT * FROM dbo.LichHen;
GO
CREATE OR ALTER VIEW dbo.vw_LichTruc AS SELECT * FROM dbo.LichTruc;
GO
CREATE OR ALTER VIEW dbo.vw_NhanVien AS SELECT * FROM dbo.NhanVien;
GO
CREATE OR ALTER VIEW dbo.vw_NoiTru AS SELECT * FROM dbo.NoiTru;
GO
CREATE OR ALTER VIEW dbo.vw_PhieuKham AS SELECT * FROM dbo.PhieuKham;
GO
CREATE OR ALTER VIEW dbo.vw_PhieuNhapKho AS SELECT * FROM dbo.PhieuNhapKho;
GO
CREATE OR ALTER VIEW dbo.vw_Phong AS
SELECT p.MaPhong, p.TenPhong, p.LoaiPhong, p.MaKhoa, p.TrangThai, k.TenKhoa
FROM dbo.Phong p JOIN dbo.Khoa k ON p.MaKhoa = k.MaKhoa;
GO
CREATE OR ALTER VIEW dbo.vw_TaiKhoan AS
SELECT MaTaiKhoan, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, TrangThai, NgayTao
FROM dbo.TaiKhoan;
GO
CREATE OR ALTER VIEW dbo.vw_ThongBao AS SELECT * FROM dbo.ThongBao;
GO
CREATE OR ALTER VIEW dbo.vw_Thuoc AS SELECT * FROM dbo.Thuoc;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauChuyenKhoa AS SELECT * FROM dbo.YeuCauChuyenKhoa;
GO

-- =========================================================================
-- 5 VIEW BÁO CÁO TỔNG HỢP THEO TIÊU CHÍ ĐỒ ÁN
-- =========================================================================

-- 1. View Thống kê doanh thu theo tháng
CREATE OR ALTER VIEW dbo.vw_BaoCaoDoanhThuTheoThang AS
SELECT 
    YEAR(NgayThanhToan) AS Nam, MONTH(NgayThanhToan) AS Thang,
    COUNT(MaHoaDon) AS SoLuongHoaDon, SUM(TongTienDichVu) AS TongTienDichVu,
    SUM(BHYTChiTra) AS TongBHYTChiTra, SUM(TongThanhToan) AS DoanhThuThucTe
FROM dbo.HoaDon WHERE TrangThaiTT = 'DaThanhToan' GROUP BY YEAR(NgayThanhToan), MONTH(NgayThanhToan);
GO

-- 2. View Báo cáo hiệu suất Bác sĩ
CREATE OR ALTER VIEW dbo.vw_BaoCaoHieuSuatBacSi AS
SELECT 
    nv.MaNhanVien, nv.HoTen AS TenBacSi, k.TenKhoa,
    COUNT(pk.MaPhieuKham) AS TongSoCaKham, SUM(hd.TongThanhToan) AS DoanhThuMangLai
FROM dbo.NhanVien nv
JOIN dbo.PhieuKham pk ON nv.MaNhanVien = pk.MaBacSi
JOIN dbo.HoaDon hd ON pk.MaPhieuKham = hd.MaPhieuKham
JOIN dbo.Khoa k ON nv.MaKhoa = k.MaKhoa
WHERE hd.TrangThaiTT = 'DaThanhToan' AND nv.VaiTro = 'BacSi'
GROUP BY nv.MaNhanVien, nv.HoTen, k.TenKhoa;
GO

-- 3. View Báo cáo tồn kho thuốc 
CREATE OR ALTER VIEW dbo.vw_BaoCaoTonKhoThuoc AS
SELECT 
    t.MaThuoc, t.TenThuoc, t.DonViTinh, t.TonKhoHienTai, t.NguongCanhBao, t.DonGiaBan,
    (t.TonKhoHienTai * t.DonGiaBan) AS TongGiaTriTon,
    CASE WHEN t.TonKhoHienTai <= t.NguongCanhBao THEN N'Cần nhập gấp' ELSE N'An toàn' END AS TrangThaiKho
FROM dbo.Thuoc t;
GO

-- 4. View Thống kê bệnh phổ biến (ICD-10)
CREATE OR ALTER VIEW dbo.vw_BaoCaoBenhPhoBien AS
SELECT TOP 100 PERCENT ChanDoan AS MaBenhICD, COUNT(MaPhieuKham) AS SoCaMac, MAX(NgayKham) AS CaMacGanNhat
FROM dbo.PhieuKham WHERE ChanDoan IS NOT NULL AND ChanDoan <> '' GROUP BY ChanDoan ORDER BY SoCaMac DESC;
GO

-- 5. View Báo cáo công suất sử dụng giường
CREATE OR ALTER VIEW dbo.vw_BaoCaoCongSuatGiuong AS
SELECT 
    p.MaPhong, p.TenPhong, k.TenKhoa, COUNT(gb.MaGiuong) AS TongSoGiuong,
    SUM(CASE WHEN gb.TrangThai = 'DangSuDung' THEN 1 ELSE 0 END) AS SoGiuongDangDung,
    SUM(CASE WHEN gb.TrangThai = 'Trong' THEN 1 ELSE 0 END) AS SoGiuongTrong,
    CAST(SUM(CASE WHEN gb.TrangThai = 'DangSuDung' THEN 1.0 ELSE 0.0 END) / COUNT(gb.MaGiuong) * 100 AS DECIMAL(5, 2)) AS TyLeLapDien
FROM dbo.Phong p JOIN dbo.GiuongBenh gb ON p.MaPhong = gb.MaPhong JOIN dbo.Khoa k ON p.MaKhoa = k.MaKhoa
GROUP BY p.MaPhong, p.TenPhong, k.TenKhoa;
GO