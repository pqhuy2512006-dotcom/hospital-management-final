/* ======================================================================
   01_Tables_Constraints.sql
   Database [QuanLyBenhVien] - Bảng và toàn bộ Ràng buộc (Inline DDL)
   ====================================================================== */
IF DB_ID(N'QuanLyBenhVien') IS NULL
BEGIN
    CREATE DATABASE [QuanLyBenhVien];
END;
GO
USE [QuanLyBenhVien];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Bảng TaiKhoan (Độc lập)
CREATE TABLE [dbo].[TaiKhoan] (
    [MaTaiKhoan] bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [TenDangNhap] varchar(50) NOT NULL UNIQUE,
    [MatKhauHash] varchar(255) NOT NULL,
    [Email] varchar(100) NULL,
    [SoDienThoai] varchar(15) NOT NULL UNIQUE,
    [VaiTro] varchar(20) NOT NULL CHECK ([VaiTro] IN ('QuanLyNhanSu','BacSi','DieuDuong','LeTan','DuocSi','KTV','ThuNgan','QuanTri','BenhNhan')),
    [TrangThai] bit NOT NULL DEFAULT 1,
    [NgayTao] datetime NOT NULL DEFAULT getdate()
);
GO

-- 2. Bảng Khoa
CREATE TABLE [dbo].[Khoa] (
    [MaKhoa] varchar(10) NOT NULL PRIMARY KEY,
    [TenKhoa] nvarchar(100) NOT NULL,
    [MoTa] nvarchar(300) NULL,
    [MaTruongKhoa] varchar(15) NULL,
    [TrangThai] bit NOT NULL DEFAULT 1
);
GO

-- 3. Bảng Phong (Tham chiếu Khoa)
CREATE TABLE [dbo].[Phong] (
    [MaPhong] varchar(15) NOT NULL PRIMARY KEY,
    [TenPhong] nvarchar(100) NOT NULL,
    [LoaiPhong] varchar(20) NOT NULL CHECK ([LoaiPhong] IN ('PHAU_THUAT','XET_NGHIEM','LUU_BENH','KHAM_BENH')),
    [MaKhoa] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [TrangThai] bit NOT NULL DEFAULT 1
);
GO

-- 4. Bảng GiuongBenh (Tham chiếu Phong)
CREATE TABLE [dbo].[GiuongBenh] (
    [MaGiuong] varchar(15) NOT NULL PRIMARY KEY,
    [SoGiuong] varchar(20) NOT NULL,
    [TrangThai] varchar(20) NOT NULL DEFAULT 'Trong' CHECK ([TrangThai] IN ('BaoTri','DangSuDung','Trong')),
    [DonGiaNgay] decimal(12,0) NOT NULL DEFAULT 0 CHECK ([DonGiaNgay] >= 0),
    [MaPhong] varchar(15) NOT NULL REFERENCES [dbo].[Phong]([MaPhong])
);
GO

-- 5. Bảng NhanVien (Tham chiếu TaiKhoan, Khoa, Phong)
CREATE TABLE [dbo].[NhanVien] (
    [MaNhanVien] varchar(15) NOT NULL PRIMARY KEY,
    [MaTaiKhoan] bigint NULL REFERENCES [dbo].[TaiKhoan]([MaTaiKhoan]),
    [HoTen] nvarchar(100) NOT NULL,
    [NgaySinh] date NULL,
    [GioiTinh] varchar(10) NULL CHECK ([GioiTinh] IN ('Nam','Nu','Khac')),
    [SoCCCD] varchar(12) NULL,
    [SoDienThoai] varchar(15) NOT NULL UNIQUE,
    [Email] varchar(100) NULL,
    [MaPhong] varchar(15) NULL REFERENCES [dbo].[Phong]([MaPhong]),
    [ChungChiHanhNghe] varchar(50) NULL,
    [TrinhDoChuyenMon] nvarchar(100) NULL,
    [NgayVaoLam] date NULL,
    [VaiTro] varchar(20) NOT NULL CHECK ([VaiTro] IN ('QuanLyNhanSu','BacSi','DieuDuong','LeTan','DuocSi','KTV','ThuNgan','QuanTri')),
    [TrangThai] varchar(20) NOT NULL DEFAULT 'DangLamViec' CHECK ([TrangThai] IN ('DangLamViec','DaNghi')),
    [MaKhoa] varchar(10) NULL REFERENCES [dbo].[Khoa]([MaKhoa])
);
GO

-- Khóa ngoại vòng: Cập nhật Trưởng khoa trỏ về Nhân viên
ALTER TABLE [dbo].[Khoa] 
ADD CONSTRAINT [FK_Khoa_TruongKhoa] FOREIGN KEY ([MaTruongKhoa]) REFERENCES [dbo].[NhanVien]([MaNhanVien]);
GO

-- 6. Bảng BenhNhan (Tham chiếu TaiKhoan)
CREATE TABLE [dbo].[BenhNhan] (
    [MaBenhNhan] varchar(15) NOT NULL PRIMARY KEY,
    [MaTaiKhoan] bigint NULL REFERENCES [dbo].[TaiKhoan]([MaTaiKhoan]),
    [HoTen] nvarchar(100) NOT NULL,
    [NgaySinh] date NOT NULL,
    [GioiTinh] varchar(10) NOT NULL CHECK ([GioiTinh] IN ('Nam','Nu','Khac')),
    [SoCCCD] varchar(12) NULL,
    [MaBHYT] varchar(15) NULL,
    [NhomMau] varchar(5) NULL,
    [NgheNghiep] nvarchar(100) NULL,
    [DiaChi] nvarchar(200) NULL,
    [SoDienThoai] varchar(15) NOT NULL,
    [Email] varchar(100) NULL,
    [NguoiLienHeKhanCap] nvarchar(100) NULL,
    [QuanHeNguoiLienHe] nvarchar(50) NULL,
    [SdtNguoiLienHe] varchar(15) NULL,
    [TienSuBenhNen] nvarchar(500) NULL,
    [TienSuDiUng] nvarchar(500) NULL,
    [NgayTaoHoSo] datetime NOT NULL DEFAULT getdate()
);
GO

-- 7. Bảng DichVuCLS (Độc lập)
CREATE TABLE [dbo].[DichVuCLS] (
    [MaDichVu] varchar(15) NOT NULL PRIMARY KEY,
    [TenDichVu] nvarchar(150) NOT NULL,
    [DonGia] decimal(12,0) NOT NULL CHECK ([DonGia] >= 0),
    [DonViTinh] nvarchar(20) NULL,
    [KhoangThamChieu] nvarchar(100) NULL
);
GO

-- 8. Bảng Thuoc (Độc lập)
CREATE TABLE [dbo].[Thuoc] (
    [MaThuoc] varchar(15) NOT NULL PRIMARY KEY,
    [TenThuoc] nvarchar(150) NOT NULL,
    [DonViTinh] varchar(20) NOT NULL,
    [DonGiaBan] decimal(12,0) NOT NULL CHECK ([DonGiaBan] >= 0),
    [TonKhoHienTai] int NOT NULL DEFAULT 0 CHECK ([TonKhoHienTai] >= 0),
    [NguongCanhBao] int NOT NULL DEFAULT 10
);
GO

-- 9. Bảng LichHen (Tham chiếu BenhNhan, Khoa, NhanVien)
CREATE TABLE [dbo].[LichHen] (
    [MaLichHen] varchar(15) NOT NULL PRIMARY KEY,
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaKhoa] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [MaBacSi] varchar(15) NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [NgayKham] date NOT NULL,
    [GioKham] time(7) NOT NULL,
    [LoaiKham] varchar(20) NOT NULL CHECK ([LoaiKham] IN ('TaiKham','KhamDichVu','KhamThuong')),
    [HinhThucDat] varchar(20) NOT NULL CHECK ([HinhThucDat] IN ('DienThoai','TrucTiep','Online')),
    [LyDoKham] nvarchar(300) NULL,
    [TrangThai] varchar(20) NOT NULL DEFAULT 'ChoXacNhan' CHECK ([TrangThai] IN ('DaHuy','DaKham','ChoKetQuaCLS','DangKham','DangChoKham','DaDatLich')),
    [NgayDatLich] datetime NOT NULL DEFAULT getdate(),
    [ThoiGianKhamDuKien] int NOT NULL,
    CONSTRAINT [CK_LichHen_ThoiGianKhamDuKien] CHECK (
        ([LoaiKham] IN ('TaiKham','KhamThuong') AND [ThoiGianKhamDuKien] = 30) OR 
        ([LoaiKham] = 'KhamDichVu' AND [ThoiGianKhamDuKien] = 45)
    )
);
GO

-- 10. Bảng PhieuKham (Tham chiếu BenhNhan, NhanVien, Khoa, LichHen)
CREATE TABLE [dbo].[PhieuKham] (
    [MaPhieuKham] varchar(15) NOT NULL PRIMARY KEY,
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaBacSi] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [MaKhoa] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [MaLichHen] varchar(15) NULL REFERENCES [dbo].[LichHen]([MaLichHen]),
    [NgayKham] datetime NOT NULL DEFAULT getdate(),
    [Mach] int NULL,
    [NhietDo] decimal(4,1) NULL,
    [HuyetAp] varchar(15) NULL,
    [NhipTho] int NULL,
    [CanNang] decimal(5,1) NULL,
    [ChieuCao] decimal(5,1) NULL,
    [TrieuChung] nvarchar(500) NULL,
    [KetQuaKhamLS] nvarchar(1000) NULL,
    [ChanDoan] nvarchar(500) NULL,
    [LoiDanBacSi] nvarchar(500) NULL,
    [NgayHenTaiKham] date NULL
);
GO

-- 11. Bảng HoaDon (Tham chiếu BenhNhan, PhieuKham, NhanVien)
CREATE TABLE [dbo].[HoaDon] (
    [MaHoaDon] varchar(15) NOT NULL PRIMARY KEY,
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaPhieuKham] varchar(15) NOT NULL REFERENCES [dbo].[PhieuKham]([MaPhieuKham]),
    [NgayLap] datetime NOT NULL DEFAULT getdate(),
    [TongTienDichVu] decimal(12,0) NOT NULL DEFAULT 0,
    [BHYTChiTra] decimal(12,0) NOT NULL DEFAULT 0,
    [TongThanhToan] AS ([TongTienDichVu]-[BHYTChiTra]) PERSISTED,
    [HinhThucThanhToan] varchar(30) NOT NULL CHECK ([HinhThucThanhToan] IN ('ViDienTu','ChuyenKhoan','TienMat')),
    [TrangThaiTT] varchar(20) NOT NULL DEFAULT 'ChuaThanhToan' CHECK ([TrangThaiTT] IN ('HoanTien','DaThanhToan','ChuaThanhToan')),
    [NhanVienThu] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [NgayThanhToan] datetime NULL
);
GO

-- 12. Bảng ChiTietHoaDon (Tham chiếu HoaDon)
CREATE TABLE [dbo].[ChiTietHoaDon] (
    [MaChiTietHD] varchar(15) NOT NULL PRIMARY KEY,
    [MaHoaDon] varchar(15) NOT NULL REFERENCES [dbo].[HoaDon]([MaHoaDon]),
    [TenDichVu] nvarchar(150) NOT NULL,
    [LoaiDichVu] varchar(20) NOT NULL CHECK ([LoaiDichVu] IN ('Giuong','Thuoc','CanLamSang','Kham')),
    [DonGia] decimal(12,0) NOT NULL CHECK ([DonGia] >= 0),
    [SoLuong] int NOT NULL DEFAULT 1 CHECK ([SoLuong] > 0),
    [ThanhTien] AS ([DonGia]*[SoLuong]) PERSISTED
);
GO

-- 13. Bảng DonThuoc (Tham chiếu PhieuKham, Thuoc)
CREATE TABLE [dbo].[DonThuoc] (
    [MaDonThuoc] varchar(15) NOT NULL PRIMARY KEY,
    [MaPhieuKham] varchar(15) NOT NULL REFERENCES [dbo].[PhieuKham]([MaPhieuKham]),
    [MaThuoc] varchar(15) NOT NULL REFERENCES [dbo].[Thuoc]([MaThuoc]),
    [SoLo] varchar(30) NULL,
    [DonViTinh] varchar(20) NOT NULL,
    [SoLuong] int NOT NULL CHECK ([SoLuong] > 0),
    [LieuDung] nvarchar(100) NULL,
    [CachDung] nvarchar(200) NULL,
    [TrangThai] varchar(20) NULL DEFAULT 'PENDING'
);
GO

-- 14. Bảng KetQuaCLS (Tham chiếu PhieuKham, BenhNhan, DichVuCLS, NhanVien)
CREATE TABLE [dbo].[KetQuaCLS] (
    [MaKetQua] varchar(15) NOT NULL PRIMARY KEY,
    [MaPhieuKham] varchar(15) NOT NULL REFERENCES [dbo].[PhieuKham]([MaPhieuKham]),
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaDichVu] varchar(15) NULL REFERENCES [dbo].[DichVuCLS]([MaDichVu]),
    [MaKTV] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [MaBacSiDoc] varchar(15) NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [LoaiXetNghiem] nvarchar(100) NOT NULL,
    [KetLuan] nvarchar(500) NULL,
    [NgayThucHien] datetime NOT NULL DEFAULT getdate(),
    [HinhAnhFile] nvarchar(MAX) NULL
);
GO

-- 15. Bảng ChiTietKetQuaCLS (Tham chiếu KetQuaCLS)
CREATE TABLE [dbo].[ChiTietKetQuaCLS] (
    [MaChiTietXN] varchar(15) NOT NULL PRIMARY KEY,
    [MaKetQua] varchar(15) NOT NULL REFERENCES [dbo].[KetQuaCLS]([MaKetQua]),
    [TenChiSo] nvarchar(100) NOT NULL,
    [GiaTri] varchar(30) NULL,
    [DonVi] varchar(20) NULL,
    [KhoangThamChieu] varchar(50) NULL,
    [DanhGia] varchar(20) NULL CHECK ([DanhGia] IN ('Thap','Cao','BinhThuong'))
);
GO

-- 16. Bảng PhieuNhapKho (Tham chiếu NhanVien)
CREATE TABLE [dbo].[PhieuNhapKho] (
    [MaPhieuNhap] varchar(15) NOT NULL PRIMARY KEY,
    [NgayNhap] date NOT NULL DEFAULT (CONVERT(date, getdate())),
    [NhaCungCap] nvarchar(150) NOT NULL,
    [SoHoaDonNCC] varchar(30) NULL,
    [NguoiNhap] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [NguoiDuyet] varchar(15) NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [TongTien] decimal(14,0) NOT NULL DEFAULT 0
);
GO

-- 17. Bảng ChiTietNhapKho (Tham chiếu PhieuNhapKho, Thuoc)
CREATE TABLE [dbo].[ChiTietNhapKho] (
    [MaChiTietNhap] varchar(15) NOT NULL PRIMARY KEY,
    [MaPhieuNhap] varchar(15) NOT NULL REFERENCES [dbo].[PhieuNhapKho]([MaPhieuNhap]),
    [MaThuoc] varchar(15) NOT NULL REFERENCES [dbo].[Thuoc]([MaThuoc]),
    [SoLo] varchar(30) NOT NULL,
    [SoLuong] int NOT NULL CHECK ([SoLuong] > 0),
    [DonGia] decimal(12,0) NOT NULL CHECK ([DonGia] >= 0),
    [ThanhTien] AS ([SoLuong]*[DonGia]) PERSISTED,
    [HanSuDung] date NOT NULL,
    [SoLuongTon] int NULL
);
GO

-- 18. Bảng NoiTru (Tham chiếu BenhNhan, GiuongBenh, PhieuKham)
CREATE TABLE [dbo].[NoiTru] (
    [MaNoiTru] varchar(15) NOT NULL PRIMARY KEY,
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaGiuong] varchar(15) NOT NULL REFERENCES [dbo].[GiuongBenh]([MaGiuong]),
    [MaPhieuKham] varchar(15) NOT NULL REFERENCES [dbo].[PhieuKham]([MaPhieuKham]),
    [NgayNhapVien] datetime NOT NULL DEFAULT getdate(),
    [NgayXuatVien] datetime NULL,
    [TrangThai] varchar(20) NOT NULL DEFAULT 'DangNam' CHECK ([TrangThai] IN ('ChuyenKhoa','DaXuatVien','DangNam')),
    CONSTRAINT [CK_NoiTru_NgayXuat] CHECK ([NgayXuatVien] IS NULL OR [NgayXuatVien] >= [NgayNhapVien])
);
GO

-- 19. Bảng LichTruc (Tham chiếu NhanVien, Khoa)
CREATE TABLE [dbo].[LichTruc] (
    [MaLichTruc] varchar(15) NOT NULL PRIMARY KEY,
    [MaNhanVien] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [Ngay] date NOT NULL,
    [Ca] varchar(10) NOT NULL CHECK ([Ca] IN ('Toi','Chieu','Sang')),
    [MaKhoa] varchar(10) NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    CONSTRAINT [UQ_LichTruc_NV_Ngay_Ca] UNIQUE ([MaNhanVien], [Ngay], [Ca])
);
GO

-- 20. Bảng LichSuPhanCongKhoa (Tham chiếu NhanVien, Khoa)
CREATE TABLE [dbo].[LichSuPhanCongKhoa] (
    [MaPhanCong] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [MaNhanVien] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [MaKhoa] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [ChucVu] nvarchar(100) NULL,
    [NgayBatDau] date NOT NULL DEFAULT (CONVERT(date, getdate())),
    [NgayKetThuc] date NULL,
    [LyDo] nvarchar(255) NULL,
    [TrangThai] nvarchar(30) NULL DEFAULT N'DangCongTac'
);
GO

-- 21. Bảng LichSuTruongKhoa (Tham chiếu Khoa, NhanVien)
CREATE TABLE [dbo].[LichSuTruongKhoa] (
    [MaLichSu] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [MaKhoa] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [MaNhanVien] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [NgayBoNhiem] datetime NULL DEFAULT getdate(),
    [NgayMienNhiem] datetime NULL
);
GO

-- 22. Bảng ThongBao (Tham chiếu TaiKhoan)
CREATE TABLE [dbo].[ThongBao] (
    [MaThongBao] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [MaTaiKhoan] bigint NOT NULL REFERENCES [dbo].[TaiKhoan]([MaTaiKhoan]),
    [TieuDe] nvarchar(200) NOT NULL,
    [NoiDung] nvarchar(1000) NOT NULL,
    [LoaiThongBao] varchar(50) NOT NULL,
    [DaDoc] bit NOT NULL DEFAULT 0,
    [NgayTao] datetime NOT NULL DEFAULT getdate()
);
GO

-- 23. Bảng YeuCauChuyenKhoa (Tham chiếu PhieuKham, BenhNhan, NhanVien, Khoa)
CREATE TABLE [dbo].[YeuCauChuyenKhoa] (
    [MaYeuCau] varchar(15) NOT NULL PRIMARY KEY,
    [LoaiYeuCau] varchar(20) NOT NULL CHECK ([LoaiYeuCau] IN ('HOI_CHAN','CHUYEN_KHOA')),
    [MaPhieuKham] varchar(15) NOT NULL REFERENCES [dbo].[PhieuKham]([MaPhieuKham]),
    [MaBenhNhan] varchar(15) NOT NULL REFERENCES [dbo].[BenhNhan]([MaBenhNhan]),
    [MaBacSiGui] varchar(15) NOT NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [MaKhoaNhan] varchar(10) NOT NULL REFERENCES [dbo].[Khoa]([MaKhoa]),
    [MaBacSiDuocMoi] varchar(15) NULL REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    [LyDo] nvarchar(500) NOT NULL,
    [TrangThai] varchar(30) NOT NULL DEFAULT 'CHO_TIEP_NHAN',
    [NgayTao] datetime2(7) NOT NULL DEFAULT sysdatetime()
);
GO

-- 24. Bảng AuditLog (Độc lập)
CREATE TABLE [dbo].[AuditLog] (
    [AuditLogId] bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [EventType] varchar(40) NOT NULL,
    [Username] varchar(50) NULL,
    [UserRole] varchar(20) NULL,
    [HttpMethod] varchar(10) NOT NULL,
    [RequestPath] varchar(255) NOT NULL,
    [HttpStatus] int NOT NULL,
    [RemoteAddress] varchar(64) NULL,
    [Details] varchar(500) NULL,
    [OccurredAt] datetime2(7) NOT NULL DEFAULT sysutcdatetime()
);
GO

/* ======================================================================
   INDEXES MỞ RỘNG (Filtered Indexes phục vụ tìm kiếm nhanh & cho phép NULL)
   ====================================================================== */
CREATE NONCLUSTERED INDEX [IX_AuditLog_OccurredAt] ON [dbo].[AuditLog] ([OccurredAt] DESC);
CREATE UNIQUE NONCLUSTERED INDEX [UIX_BenhNhan_MaTaiKhoan] ON [dbo].[BenhNhan] ([MaTaiKhoan] ASC) WHERE ([MaTaiKhoan] IS NOT NULL);
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BenhNhan_BHYT] ON [dbo].[BenhNhan] ([MaBHYT] ASC) WHERE ([MaBHYT] IS NOT NULL AND [MaBHYT] <> '');
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BenhNhan_CCCD] ON [dbo].[BenhNhan] ([SoCCCD] ASC) WHERE ([SoCCCD] IS NOT NULL);
CREATE UNIQUE NONCLUSTERED INDEX [UQ_NhanVien_CCCD] ON [dbo].[NhanVien] ([SoCCCD] ASC) WHERE ([SoCCCD] IS NOT NULL);
CREATE UNIQUE NONCLUSTERED INDEX [UQ_NhanVien_MaTaiKhoan] ON [dbo].[NhanVien] ([MaTaiKhoan] ASC) WHERE ([MaTaiKhoan] IS NOT NULL);
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaiKhoan_Email_Filtered] ON [dbo].[TaiKhoan] ([Email] ASC) WHERE ([Email] IS NOT NULL);
CREATE NONCLUSTERED INDEX [IX_YeuCauChuyenKhoa_BacSiNgay] ON [dbo].[YeuCauChuyenKhoa] ([MaBacSiGui] ASC, [NgayTao] DESC);
GO
