/* ======================================================================
   01_Tables_Constraints.sql
   Database [QuanLyBenhVien] - Tables, Primary Keys, Indexes & Constraints
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

CREATE TABLE [dbo].[AuditLog] (
    [AuditLogId] bigint IDENTITY(1,1) NOT NULL,
    [EventType] varchar(40) NOT NULL,
    [Username] varchar(50) NULL,
    [UserRole] varchar(20) NULL,
    [HttpMethod] varchar(10) NOT NULL,
    [RequestPath] varchar(255) NOT NULL,
    [HttpStatus] int NOT NULL,
    [RemoteAddress] varchar(64) NULL,
    [Details] varchar(500) NULL,
    [OccurredAt] datetime2(7) CONSTRAINT [DF__AuditLog__Occurr__3C34F16F] DEFAULT (sysutcdatetime()) NOT NULL
);
GO

CREATE TABLE [dbo].[BenhNhan] (
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaTaiKhoan] bigint NULL,
    [HoTen] nvarchar(100) NOT NULL,
    [NgaySinh] date NOT NULL,
    [GioiTinh] varchar(10) NOT NULL,
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
    [NgayTaoHoSo] datetime CONSTRAINT [DF__BenhNhan__NgayTa__628FA481] DEFAULT (getdate()) NOT NULL
);
GO

CREATE TABLE [dbo].[ChiTietHoaDon] (
    [MaChiTietHD] varchar(15) NOT NULL,
    [MaHoaDon] varchar(15) NOT NULL,
    [TenDichVu] nvarchar(150) NOT NULL,
    [LoaiDichVu] varchar(20) NOT NULL,
    [DonGia] decimal(12,0) NOT NULL,
    [SoLuong] int CONSTRAINT [DF__ChiTietHo__SoLuo__367C1819] DEFAULT ((1)) NOT NULL,
    [ThanhTien] AS ([DonGia]*[SoLuong]) PERSISTED
);
GO

CREATE TABLE [dbo].[ChiTietKetQuaCLS] (
    [MaChiTietXN] varchar(15) NOT NULL,
    [MaKetQua] varchar(15) NOT NULL,
    [TenChiSo] nvarchar(100) NOT NULL,
    [GiaTri] varchar(30) NULL,
    [DonVi] varchar(20) NULL,
    [KhoangThamChieu] varchar(50) NULL,
    [DanhGia] varchar(20) NULL
);
GO

CREATE TABLE [dbo].[ChiTietNhapKho] (
    [MaChiTietNhap] varchar(15) NOT NULL,
    [MaPhieuNhap] varchar(15) NOT NULL,
    [MaThuoc] varchar(15) NOT NULL,
    [SoLo] varchar(30) NOT NULL,
    [SoLuong] int NOT NULL,
    [DonGia] decimal(12,0) NOT NULL,
    [ThanhTien] AS ([SoLuong]*[DonGia]) PERSISTED,
    [HanSuDung] date NOT NULL,
    [SoLuongTon] int NULL
);
GO

CREATE TABLE [dbo].[DichVuCLS] (
    [MaDichVu] varchar(15) NOT NULL,
    [TenDichVu] nvarchar(150) NOT NULL,
    [DonGia] decimal(12,0) NOT NULL,
    [DonViTinh] nvarchar(20) NULL,
    [KhoangThamChieu] nvarchar(100) NULL
);
GO

CREATE TABLE [dbo].[DonThuoc] (
    [MaDonThuoc] varchar(15) NOT NULL,
    [MaPhieuKham] varchar(15) NOT NULL,
    [MaThuoc] varchar(15) NOT NULL,
    [SoLo] varchar(30) NULL,
    [DonViTinh] varchar(20) NOT NULL,
    [SoLuong] int NOT NULL,
    [LieuDung] nvarchar(100) NULL,
    [CachDung] nvarchar(200) NULL,
    [TrangThai] varchar(20) CONSTRAINT [DF__DonThuoc__TrangT__7908F585] DEFAULT ('PENDING') NULL
);
GO

CREATE TABLE [dbo].[GiuongBenh] (
    [MaGiuong] varchar(15) NOT NULL,
    [SoGiuong] varchar(20) NOT NULL,
    [TrangThai] varchar(20) CONSTRAINT [DF__GiuongBen__Trang__7C4F7684] DEFAULT ('Trong') NOT NULL,
    [DonGiaNgay] decimal(12,0) CONSTRAINT [DF__GiuongBen__DonGi__7E37BEF6] DEFAULT ((0)) NOT NULL,
    [MaPhong] varchar(15) NOT NULL
);
GO

CREATE TABLE [dbo].[HoaDon] (
    [MaHoaDon] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaPhieuKham] varchar(15) NOT NULL,
    [NgayLap] datetime CONSTRAINT [DF__HoaDon__NgayLap__2A164134] DEFAULT (getdate()) NOT NULL,
    [TongTienDichVu] decimal(12,0) CONSTRAINT [DF__HoaDon__TongTien__2B0A656D] DEFAULT ((0)) NOT NULL,
    [BHYTChiTra] decimal(12,0) CONSTRAINT [DF__HoaDon__BHYTChiT__2BFE89A6] DEFAULT ((0)) NOT NULL,
    [TongThanhToan] AS ([TongTienDichVu]-[BHYTChiTra]) PERSISTED,
    [HinhThucThanhToan] varchar(30) NOT NULL,
    [TrangThaiTT] varchar(20) CONSTRAINT [DF__HoaDon__TrangTha__2DE6D218] DEFAULT ('ChuaThanhToan') NOT NULL,
    [NhanVienThu] varchar(15) NOT NULL,
    [NgayThanhToan] datetime NULL
);
GO

CREATE TABLE [dbo].[KetQuaCLS] (
    [MaKetQua] varchar(15) NOT NULL,
    [MaPhieuKham] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaDichVu] varchar(15) NULL,
    [MaKTV] varchar(15) NOT NULL,
    [MaBacSiDoc] varchar(15) NULL,
    [LoaiXetNghiem] nvarchar(100) NOT NULL,
    [KetLuan] nvarchar(500) NULL,
    [NgayThucHien] datetime CONSTRAINT [DF__KetQuaCLS__NgayT__1332DBDC] DEFAULT (getdate()) NOT NULL,
    [HinhAnhFile] nvarchar(MAX) NULL
);
GO

CREATE TABLE [dbo].[Khoa] (
    [MaKhoa] varchar(10) NOT NULL,
    [TenKhoa] nvarchar(100) NOT NULL,
    [MoTa] nvarchar(300) NULL,
    [MaTruongKhoa] varchar(15) NULL,
    [TrangThai] bit CONSTRAINT [DF__Khoa__TrangThai__473C8FC7] DEFAULT ((1)) NOT NULL
);
GO

CREATE TABLE [dbo].[LichHen] (
    [MaLichHen] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaKhoa] varchar(10) NOT NULL,
    [MaBacSi] varchar(15) NULL,
    [NgayKham] date NOT NULL,
    [GioKham] time(7) NOT NULL,
    [LoaiKham] varchar(20) NOT NULL,
    [HinhThucDat] varchar(20) NOT NULL,
    [LyDoKham] nvarchar(300) NULL,
    [TrangThai] varchar(20) CONSTRAINT [DF__LichHen__TrangTh__6E01572D] DEFAULT ('ChoXacNhan') NOT NULL,
    [NgayDatLich] datetime CONSTRAINT [DF__LichHen__NgayDat__6FE99F9F] DEFAULT (getdate()) NOT NULL,
    [ThoiGianKhamDuKien] int NOT NULL
);
GO

CREATE TABLE [dbo].[LichSuPhanCongKhoa] (
    [MaPhanCong] int IDENTITY(1,1) NOT NULL,
    [MaNhanVien] varchar(15) NOT NULL,
    [MaKhoa] varchar(10) NOT NULL,
    [ChucVu] nvarchar(100) NULL,
    [NgayBatDau] date CONSTRAINT [DF__LichSuPha__NgayB__3429BB53] DEFAULT (CONVERT([date],getdate())) NOT NULL,
    [NgayKetThuc] date NULL,
    [LyDo] nvarchar(255) NULL,
    [TrangThai] nvarchar(30) CONSTRAINT [DF__LichSuPha__Trang__351DDF8C] DEFAULT (N'DangCongTac') NULL
);
GO

CREATE TABLE [dbo].[LichSuTruongKhoa] (
    [MaLichSu] int IDENTITY(1,1) NOT NULL,
    [MaKhoa] varchar(10) NOT NULL,
    [MaNhanVien] varchar(15) NOT NULL,
    [NgayBoNhiem] datetime CONSTRAINT [DF__LichSuTru__NgayB__2D7CBDC4] DEFAULT (getdate()) NULL,
    [NgayMienNhiem] datetime NULL
);
GO

CREATE TABLE [dbo].[LichTruc] (
    [MaLichTruc] varchar(15) NOT NULL,
    [MaNhanVien] varchar(15) NOT NULL,
    [Ngay] date NOT NULL,
    [Ca] varchar(10) NOT NULL,
    [MaKhoa] varchar(10) NULL
);
GO

CREATE TABLE [dbo].[NhanVien] (
    [MaNhanVien] varchar(15) NOT NULL,
    [MaTaiKhoan] bigint NULL,
    [HoTen] nvarchar(100) NOT NULL,
    [NgaySinh] date NULL,
    [GioiTinh] varchar(10) NULL,
    [SoCCCD] varchar(12) NULL,
    [SoDienThoai] varchar(15) NOT NULL,
    [Email] varchar(100) NULL,
    [MaPhong] varchar(15) NULL,
    [ChungChiHanhNghe] varchar(50) NULL,
    [TrinhDoChuyenMon] nvarchar(100) NULL,
    [NgayVaoLam] date NULL,
    [VaiTro] varchar(20) NOT NULL,
    [TrangThai] varchar(20) CONSTRAINT [DF__NhanVien__TrangT__5BE2A6F2] DEFAULT ('DangLamViec') NOT NULL,
    [MaKhoa] varchar(10) NULL
);
GO

CREATE TABLE [dbo].[NoiTru] (
    [MaNoiTru] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaGiuong] varchar(15) NOT NULL,
    [MaPhieuKham] varchar(15) NOT NULL,
    [NgayNhapVien] datetime CONSTRAINT [DF__NoiTru__NgayNhap__02FC7413] DEFAULT (getdate()) NOT NULL,
    [NgayXuatVien] datetime NULL,
    [TrangThai] varchar(20) CONSTRAINT [DF__NoiTru__TrangTha__03F0984C] DEFAULT ('DangNam') NOT NULL
);
GO

CREATE TABLE [dbo].[PhieuKham] (
    [MaPhieuKham] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaBacSi] varchar(15) NOT NULL,
    [MaKhoa] varchar(10) NOT NULL,
    [MaLichHen] varchar(15) NULL,
    [NgayKham] datetime CONSTRAINT [DF__PhieuKham__NgayK__75A278F5] DEFAULT (getdate()) NOT NULL,
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

CREATE TABLE [dbo].[PhieuNhapKho] (
    [MaPhieuNhap] varchar(15) NOT NULL,
    [NgayNhap] date CONSTRAINT [DF__PhieuNhap__NgayN__1EA48E88] DEFAULT (CONVERT([date],getdate())) NOT NULL,
    [NhaCungCap] nvarchar(150) NOT NULL,
    [SoHoaDonNCC] varchar(30) NULL,
    [NguoiNhap] varchar(15) NOT NULL,
    [NguoiDuyet] varchar(15) NULL,
    [TongTien] decimal(14,0) CONSTRAINT [DF__PhieuNhap__TongT__1F98B2C1] DEFAULT ((0)) NOT NULL
);
GO

CREATE TABLE [dbo].[Phong] (
    [MaPhong] varchar(15) NOT NULL,
    [TenPhong] nvarchar(100) NOT NULL,
    [LoaiPhong] varchar(20) NOT NULL,
    [MaKhoa] varchar(10) NOT NULL,
    [TrangThai] bit CONSTRAINT [DF__Phong__TrangThai__27C3E46E] DEFAULT ((1)) NOT NULL
);
GO

CREATE TABLE [dbo].[TaiKhoan] (
    [MaTaiKhoan] bigint IDENTITY(1,1) NOT NULL,
    [TenDangNhap] varchar(50) NOT NULL,
    [MatKhauHash] varchar(255) NOT NULL,
    [Email] varchar(100) NULL,
    [VaiTro] varchar(20) NOT NULL,
    [TrangThai] bit CONSTRAINT [DF__TaiKhoan__TrangT__4CA06362] DEFAULT ((1)) NOT NULL,
    [NgayTao] datetime CONSTRAINT [DF__TaiKhoan__NgayTa__4D94879B] DEFAULT (getdate()) NOT NULL,
    [SoDienThoai] varchar(15) NOT NULL
);
GO

CREATE TABLE [dbo].[ThongBao] (
    [MaThongBao] int IDENTITY(1,1) NOT NULL,
    [MaTaiKhoan] bigint NOT NULL,
    [TieuDe] nvarchar(200) NOT NULL,
    [NoiDung] nvarchar(1000) NOT NULL,
    [LoaiThongBao] varchar(50) NOT NULL,
    [DaDoc] bit CONSTRAINT [DF__ThongBao__DaDoc__42ACE4D4] DEFAULT ((0)) NOT NULL,
    [NgayTao] datetime CONSTRAINT [DF__ThongBao__NgayTa__43A1090D] DEFAULT (getdate()) NOT NULL
);
GO

CREATE TABLE [dbo].[Thuoc] (
    [MaThuoc] varchar(15) NOT NULL,
    [TenThuoc] nvarchar(150) NOT NULL,
    [DonViTinh] varchar(20) NOT NULL,
    [DonGiaBan] decimal(12,0) NOT NULL,
    [TonKhoHienTai] int CONSTRAINT [DF__Thuoc__TonKhoHie__534D60F1] DEFAULT ((0)) NOT NULL,
    [NguongCanhBao] int CONSTRAINT [DF__Thuoc__NguongCan__5535A963] DEFAULT ((10)) NOT NULL
);
GO

CREATE TABLE [dbo].[YeuCauChuyenKhoa] (
    [MaYeuCau] varchar(15) NOT NULL,
    [LoaiYeuCau] varchar(20) NOT NULL,
    [MaPhieuKham] varchar(15) NOT NULL,
    [MaBenhNhan] varchar(15) NOT NULL,
    [MaBacSiGui] varchar(15) NOT NULL,
    [MaKhoaNhan] varchar(10) NOT NULL,
    [MaBacSiDuocMoi] varchar(15) NULL,
    [LyDo] nvarchar(500) NOT NULL,
    [TrangThai] varchar(30) CONSTRAINT [DF__YeuCauChu__Trang__40058253] DEFAULT ('CHO_TIEP_NHAN') NOT NULL,
    [NgayTao] datetime2(7) CONSTRAINT [DF__YeuCauChu__NgayT__40F9A68C] DEFAULT (sysdatetime()) NOT NULL
);
GO

/* ---------- PRIMARY KEYS & UNIQUE CONSTRAINTS ---------- */
ALTER TABLE [dbo].[AuditLog] ADD CONSTRAINT [PK__AuditLog__EB5F6CBD493EA5A7] PRIMARY KEY ([AuditLogId] ASC);
GO
ALTER TABLE [dbo].[BenhNhan] ADD CONSTRAINT [PK__BenhNhan__22A8B33002329E1C] PRIMARY KEY ([MaBenhNhan] ASC);
GO
ALTER TABLE [dbo].[ChiTietHoaDon] ADD CONSTRAINT [PK__ChiTietH__651E49EB17DDFA94] PRIMARY KEY ([MaChiTietHD] ASC);
GO
ALTER TABLE [dbo].[ChiTietKetQuaCLS] ADD CONSTRAINT [PK__ChiTietK__651DCBF1E762E3D7] PRIMARY KEY ([MaChiTietXN] ASC);
GO
ALTER TABLE [dbo].[ChiTietNhapKho] ADD CONSTRAINT [PK__ChiTietN__D10F254C8741E985] PRIMARY KEY ([MaChiTietNhap] ASC);
GO
ALTER TABLE [dbo].[DichVuCLS] ADD CONSTRAINT [PK__DichVuCL__C0E6DE8F4E7B8867] PRIMARY KEY ([MaDichVu] ASC);
GO
ALTER TABLE [dbo].[DonThuoc] ADD CONSTRAINT [PK__DonThuoc__3EF99EE1208822BA] PRIMARY KEY ([MaDonThuoc] ASC);
GO
ALTER TABLE [dbo].[GiuongBenh] ADD CONSTRAINT [PK__GiuongBe__9C9FF4DC89F8AC4C] PRIMARY KEY ([MaGiuong] ASC);
GO
ALTER TABLE [dbo].[HoaDon] ADD CONSTRAINT [PK__HoaDon__835ED13B1CDA6A2C] PRIMARY KEY ([MaHoaDon] ASC);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [PK__KetQuaCL__D5B3102A466943B4] PRIMARY KEY ([MaKetQua] ASC);
GO
ALTER TABLE [dbo].[Khoa] ADD CONSTRAINT [PK__Khoa__6539040565F75414] PRIMARY KEY ([MaKhoa] ASC);
GO
ALTER TABLE [dbo].[LichHen] ADD CONSTRAINT [PK__LichHen__150F264F38DDA557] PRIMARY KEY ([MaLichHen] ASC);
GO
ALTER TABLE [dbo].[LichSuPhanCongKhoa] ADD CONSTRAINT [PK__LichSuPh__C279D916BF4D0CFF] PRIMARY KEY ([MaPhanCong] ASC);
GO
ALTER TABLE [dbo].[LichSuTruongKhoa] ADD CONSTRAINT [PK__LichSuTr__C443222A99C91B34] PRIMARY KEY ([MaLichSu] ASC);
GO
ALTER TABLE [dbo].[LichTruc] ADD CONSTRAINT [PK__LichTruc__9EB5133C41CE73ED] PRIMARY KEY ([MaLichTruc] ASC);
GO
ALTER TABLE [dbo].[NhanVien] ADD CONSTRAINT [PK__NhanVien__77B2CA47A10B33CF] PRIMARY KEY ([MaNhanVien] ASC);
GO
ALTER TABLE [dbo].[NoiTru] ADD CONSTRAINT [PK__NoiTru__138E961D81AA66B5] PRIMARY KEY ([MaNoiTru] ASC);
GO
ALTER TABLE [dbo].[PhieuKham] ADD CONSTRAINT [PK__PhieuKha__FACA55DF4BC9602C] PRIMARY KEY ([MaPhieuKham] ASC);
GO
ALTER TABLE [dbo].[PhieuNhapKho] ADD CONSTRAINT [PK__PhieuNha__1470EF3B5A1F48BB] PRIMARY KEY ([MaPhieuNhap] ASC);
GO
ALTER TABLE [dbo].[Phong] ADD CONSTRAINT [PK__Phong__20BD5E5B8363B07B] PRIMARY KEY ([MaPhong] ASC);
GO
ALTER TABLE [dbo].[TaiKhoan] ADD CONSTRAINT [PK__TaiKhoan__AD7C6529FB783FA4] PRIMARY KEY ([MaTaiKhoan] ASC);
GO
ALTER TABLE [dbo].[ThongBao] ADD CONSTRAINT [PK__ThongBao__04DEB54E6AB8AA08] PRIMARY KEY ([MaThongBao] ASC);
GO
ALTER TABLE [dbo].[Thuoc] ADD CONSTRAINT [PK__Thuoc__4BB1F6201E2C0BB3] PRIMARY KEY ([MaThuoc] ASC);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [PK__YeuCauCh__CFA5DF4E9D782393] PRIMARY KEY ([MaYeuCau] ASC);
GO
ALTER TABLE [dbo].[LichTruc] ADD CONSTRAINT [UQ_LichTruc_NV_Ngay_Ca] UNIQUE ([MaNhanVien] ASC, [Ngay] ASC, [Ca] ASC);
GO
ALTER TABLE [dbo].[NhanVien] ADD CONSTRAINT [UQ_NhanVien_SDT] UNIQUE ([SoDienThoai] ASC);
GO
ALTER TABLE [dbo].[TaiKhoan] ADD CONSTRAINT [UQ__TaiKhoan__55F68FC0FEE7925A] UNIQUE ([TenDangNhap] ASC);
GO
ALTER TABLE [dbo].[TaiKhoan] ADD CONSTRAINT [UQ_SDT] UNIQUE ([SoDienThoai] ASC);
GO

/* ---------- INDEXES ---------- */
CREATE NONCLUSTERED INDEX [IX_AuditLog_OccurredAt] ON [dbo].[AuditLog] ([OccurredAt] DESC);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UIX_BenhNhan_MaTaiKhoan] ON [dbo].[BenhNhan] ([MaTaiKhoan] ASC) WHERE ([MaTaiKhoan] IS NOT NULL);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BenhNhan_BHYT] ON [dbo].[BenhNhan] ([MaBHYT] ASC) WHERE ([MaBHYT] IS NOT NULL AND [MaBHYT]<>'');
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BenhNhan_CCCD] ON [dbo].[BenhNhan] ([SoCCCD] ASC) WHERE ([SoCCCD] IS NOT NULL);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_NhanVien_CCCD] ON [dbo].[NhanVien] ([SoCCCD] ASC) WHERE ([SoCCCD] IS NOT NULL);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_NhanVien_MaTaiKhoan] ON [dbo].[NhanVien] ([MaTaiKhoan] ASC) WHERE ([MaTaiKhoan] IS NOT NULL);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaiKhoan_Email_Filtered] ON [dbo].[TaiKhoan] ([Email] ASC) WHERE ([Email] IS NOT NULL);
GO
CREATE NONCLUSTERED INDEX [IX_YeuCauChuyenKhoa_BacSiNgay] ON [dbo].[YeuCauChuyenKhoa] ([MaBacSiGui] ASC, [NgayTao] DESC);
GO

/* ---------- FOREIGN KEYS ---------- */
ALTER TABLE [dbo].[BenhNhan] ADD CONSTRAINT [FK_BenhNhan_TaiKhoan] FOREIGN KEY ([MaTaiKhoan]) REFERENCES [dbo].[TaiKhoan] ([MaTaiKhoan]);
GO
ALTER TABLE [dbo].[ChiTietHoaDon] ADD CONSTRAINT [FK_ChiTietHD_HoaDon] FOREIGN KEY ([MaHoaDon]) REFERENCES [dbo].[HoaDon] ([MaHoaDon]);
GO
ALTER TABLE [dbo].[ChiTietKetQuaCLS] ADD CONSTRAINT [FK_ChiTietKQCLS_KetQuaCLS] FOREIGN KEY ([MaKetQua]) REFERENCES [dbo].[KetQuaCLS] ([MaKetQua]);
GO
ALTER TABLE [dbo].[ChiTietNhapKho] ADD CONSTRAINT [FK_ChiTietNhap_PhieuNhap] FOREIGN KEY ([MaPhieuNhap]) REFERENCES [dbo].[PhieuNhapKho] ([MaPhieuNhap]);
GO
ALTER TABLE [dbo].[ChiTietNhapKho] ADD CONSTRAINT [FK_ChiTietNhap_Thuoc] FOREIGN KEY ([MaThuoc]) REFERENCES [dbo].[Thuoc] ([MaThuoc]);
GO
ALTER TABLE [dbo].[DonThuoc] ADD CONSTRAINT [FK_DonThuoc_PhieuKham] FOREIGN KEY ([MaPhieuKham]) REFERENCES [dbo].[PhieuKham] ([MaPhieuKham]);
GO
ALTER TABLE [dbo].[DonThuoc] ADD CONSTRAINT [FK_DonThuoc_Thuoc] FOREIGN KEY ([MaThuoc]) REFERENCES [dbo].[Thuoc] ([MaThuoc]);
GO
ALTER TABLE [dbo].[GiuongBenh] ADD CONSTRAINT [FK_GiuongBenh_Phong] FOREIGN KEY ([MaPhong]) REFERENCES [dbo].[Phong] ([MaPhong]);
GO
ALTER TABLE [dbo].[HoaDon] ADD CONSTRAINT [FK_HoaDon_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[HoaDon] ADD CONSTRAINT [FK_HoaDon_NhanVien] FOREIGN KEY ([NhanVienThu]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[HoaDon] ADD CONSTRAINT [FK_HoaDon_PhieuKham] FOREIGN KEY ([MaPhieuKham]) REFERENCES [dbo].[PhieuKham] ([MaPhieuKham]);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [FK_KetQuaCLS_BacSiDoc] FOREIGN KEY ([MaBacSiDoc]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [FK_KetQuaCLS_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [FK_KetQuaCLS_DichVu] FOREIGN KEY ([MaDichVu]) REFERENCES [dbo].[DichVuCLS] ([MaDichVu]);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [FK_KetQuaCLS_KTV] FOREIGN KEY ([MaKTV]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[KetQuaCLS] ADD CONSTRAINT [FK_KetQuaCLS_PhieuKham] FOREIGN KEY ([MaPhieuKham]) REFERENCES [dbo].[PhieuKham] ([MaPhieuKham]);
GO
ALTER TABLE [dbo].[Khoa] ADD CONSTRAINT [FK_Khoa_TruongKhoa] FOREIGN KEY ([MaTruongKhoa]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[LichHen] ADD CONSTRAINT [FK_LichHen_BacSi] FOREIGN KEY ([MaBacSi]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[LichHen] ADD CONSTRAINT [FK_LichHen_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[LichHen] ADD CONSTRAINT [FK_LichHen_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[LichSuPhanCongKhoa] ADD CONSTRAINT [FK_LSPC_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[LichSuPhanCongKhoa] ADD CONSTRAINT [FK_LSPC_NhanVien] FOREIGN KEY ([MaNhanVien]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[LichSuTruongKhoa] ADD CONSTRAINT [FK_LichSu_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[LichSuTruongKhoa] ADD CONSTRAINT [FK_LichSu_NhanVien] FOREIGN KEY ([MaNhanVien]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[LichTruc] ADD CONSTRAINT [FK_LichTruc_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[LichTruc] ADD CONSTRAINT [FK_LichTruc_NhanVien] FOREIGN KEY ([MaNhanVien]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[NhanVien] ADD CONSTRAINT [FK_NhanVien_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[NhanVien] ADD CONSTRAINT [FK_NhanVien_MaPhong] FOREIGN KEY ([MaPhong]) REFERENCES [dbo].[Phong] ([MaPhong]);
GO
ALTER TABLE [dbo].[NhanVien] ADD CONSTRAINT [FK_NhanVien_TaiKhoan] FOREIGN KEY ([MaTaiKhoan]) REFERENCES [dbo].[TaiKhoan] ([MaTaiKhoan]);
GO
ALTER TABLE [dbo].[NoiTru] ADD CONSTRAINT [FK_NoiTru_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[NoiTru] ADD CONSTRAINT [FK_NoiTru_Giuong] FOREIGN KEY ([MaGiuong]) REFERENCES [dbo].[GiuongBenh] ([MaGiuong]);
GO
ALTER TABLE [dbo].[NoiTru] ADD CONSTRAINT [FK_NoiTru_PhieuKham] FOREIGN KEY ([MaPhieuKham]) REFERENCES [dbo].[PhieuKham] ([MaPhieuKham]);
GO
ALTER TABLE [dbo].[PhieuKham] ADD CONSTRAINT [FK_PhieuKham_BacSi] FOREIGN KEY ([MaBacSi]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[PhieuKham] ADD CONSTRAINT [FK_PhieuKham_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[PhieuKham] ADD CONSTRAINT [FK_PhieuKham_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[PhieuKham] ADD CONSTRAINT [FK_PhieuKham_LichHen] FOREIGN KEY ([MaLichHen]) REFERENCES [dbo].[LichHen] ([MaLichHen]);
GO
ALTER TABLE [dbo].[PhieuNhapKho] ADD CONSTRAINT [FK_PhieuNhap_NguoiDuyet] FOREIGN KEY ([NguoiDuyet]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[PhieuNhapKho] ADD CONSTRAINT [FK_PhieuNhap_NguoiNhap] FOREIGN KEY ([NguoiNhap]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[Phong] ADD CONSTRAINT [FK_Phong_Khoa] FOREIGN KEY ([MaKhoa]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[ThongBao] ADD CONSTRAINT [FK_ThongBao_TaiKhoan] FOREIGN KEY ([MaTaiKhoan]) REFERENCES [dbo].[TaiKhoan] ([MaTaiKhoan]);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [FK_YeuCauChuyenKhoa_BacSiGui] FOREIGN KEY ([MaBacSiGui]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [FK_YeuCauChuyenKhoa_BacSiMoi] FOREIGN KEY ([MaBacSiDuocMoi]) REFERENCES [dbo].[NhanVien] ([MaNhanVien]);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [FK_YeuCauChuyenKhoa_BenhNhan] FOREIGN KEY ([MaBenhNhan]) REFERENCES [dbo].[BenhNhan] ([MaBenhNhan]);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [FK_YeuCauChuyenKhoa_KhoaNhan] FOREIGN KEY ([MaKhoaNhan]) REFERENCES [dbo].[Khoa] ([MaKhoa]);
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] ADD CONSTRAINT [FK_YeuCauChuyenKhoa_PhieuKham] FOREIGN KEY ([MaPhieuKham]) REFERENCES [dbo].[PhieuKham] ([MaPhieuKham]);
GO

/* ---------- CHECK CONSTRAINTS ---------- */
ALTER TABLE [dbo].[BenhNhan] WITH CHECK ADD CONSTRAINT [CK__BenhNhan__GioiTi__619B8048] CHECK ([GioiTinh]='Khac' OR [GioiTinh]='Nu' OR [GioiTinh]='Nam');
GO
ALTER TABLE [dbo].[ChiTietHoaDon] WITH CHECK ADD CONSTRAINT [CK__ChiTietHo__DonGi__3587F3E0] CHECK ([DonGia]>=(0));
GO
ALTER TABLE [dbo].[ChiTietHoaDon] WITH CHECK ADD CONSTRAINT [CK__ChiTietHo__LoaiD__3493CFA7] CHECK ([LoaiDichVu]='Giuong' OR [LoaiDichVu]='Thuoc' OR [LoaiDichVu]='CanLamSang' OR [LoaiDichVu]='Kham');
GO
ALTER TABLE [dbo].[ChiTietHoaDon] WITH CHECK ADD CONSTRAINT [CK__ChiTietHo__SoLuo__37703C52] CHECK ([SoLuong]>(0));
GO
ALTER TABLE [dbo].[ChiTietKetQuaCLS] WITH CHECK ADD CONSTRAINT [CK__ChiTietKe__DanhG__1AD3FDA4] CHECK ([DanhGia]='Thap' OR [DanhGia]='Cao' OR [DanhGia]='BinhThuong');
GO
ALTER TABLE [dbo].[ChiTietNhapKho] WITH CHECK ADD CONSTRAINT [CK__ChiTietNh__DonGi__25518C17] CHECK ([DonGia]>=(0));
GO
ALTER TABLE [dbo].[ChiTietNhapKho] WITH CHECK ADD CONSTRAINT [CK__ChiTietNh__SoLuo__245D67DE] CHECK ([SoLuong]>(0));
GO
ALTER TABLE [dbo].[DichVuCLS] WITH CHECK ADD CONSTRAINT [CK__DichVuCLS__DonGi__10566F31] CHECK ([DonGia]>=(0));
GO
ALTER TABLE [dbo].[DonThuoc] WITH CHECK ADD CONSTRAINT [CK__DonThuoc__SoLuon__0B91BA14] CHECK ([SoLuong]>(0));
GO
ALTER TABLE [dbo].[GiuongBenh] WITH CHECK ADD CONSTRAINT [CK__GiuongBen__DonGi__7F2BE32F] CHECK ([DonGiaNgay]>=(0));
GO
ALTER TABLE [dbo].[GiuongBenh] WITH CHECK ADD CONSTRAINT [CK__GiuongBen__Trang__7D439ABD] CHECK ([TrangThai]='BaoTri' OR [TrangThai]='DangSuDung' OR [TrangThai]='Trong');
GO
ALTER TABLE [dbo].[HoaDon] WITH CHECK ADD CONSTRAINT [CK__HoaDon__HinhThuc__2CF2ADDF] CHECK ([HinhThucThanhToan]='ViDienTu' OR [HinhThucThanhToan]='ChuyenKhoan' OR [HinhThucThanhToan]='TienMat');
GO
ALTER TABLE [dbo].[HoaDon] WITH CHECK ADD CONSTRAINT [CK__HoaDon__TrangTha__2EDAF651] CHECK ([TrangThaiTT]='HoanTien' OR [TrangThaiTT]='DaThanhToan' OR [TrangThaiTT]='ChuaThanhToan');
GO
ALTER TABLE [dbo].[LichHen] WITH CHECK ADD CONSTRAINT [CK__LichHen__HinhThu__6D0D32F4] CHECK ([HinhThucDat]='DienThoai' OR [HinhThucDat]='TrucTiep' OR [HinhThucDat]='Online');
GO
ALTER TABLE [dbo].[LichHen] WITH CHECK ADD CONSTRAINT [CK__LichHen__LoaiKha__6C190EBB] CHECK ([LoaiKham]='TaiKham' OR [LoaiKham]='KhamDichVu' OR [LoaiKham]='KhamThuong');
GO
ALTER TABLE [dbo].[LichHen] WITH CHECK ADD CONSTRAINT [CK_LichHen_ThoiGianKhamDuKien] CHECK (([LoaiKham]='TaiKham' OR [LoaiKham]='KhamThuong') AND [ThoiGianKhamDuKien]=(30) OR [LoaiKham]='KhamDichVu' AND [ThoiGianKhamDuKien]=(45));
GO
ALTER TABLE [dbo].[LichHen] WITH CHECK ADD CONSTRAINT [CK_LichHen_TrangThai] CHECK ([TrangThai]='DaHuy' OR [TrangThai]='DaKham' OR [TrangThai]='ChoKetQuaCLS' OR [TrangThai]='DangKham' OR [TrangThai]='DangChoKham' OR [TrangThai]='DaDatLich');
GO
ALTER TABLE [dbo].[LichTruc] WITH CHECK ADD CONSTRAINT [CK__LichTruc__Ca__6754599E] CHECK ([Ca]='Toi' OR [Ca]='Chieu' OR [Ca]='Sang');
GO
ALTER TABLE [dbo].[NhanVien] WITH CHECK ADD CONSTRAINT [CK__NhanVien__GioiTi__59FA5E80] CHECK ([GioiTinh]='Khac' OR [GioiTinh]='Nu' OR [GioiTinh]='Nam');
GO
ALTER TABLE [dbo].[NhanVien] WITH CHECK ADD CONSTRAINT [CK__NhanVien__TrangT__5CD6CB2B] CHECK ([TrangThai]='DaNghi' OR [TrangThai]='DangLamViec');
GO
ALTER TABLE [dbo].[NhanVien] WITH CHECK ADD CONSTRAINT [CK_NhanVien_VaiTro] CHECK ([VaiTro]='QuanLyNhanSu' OR [VaiTro]='BacSi' OR [VaiTro]='DieuDuong' OR [VaiTro]='LeTan' OR [VaiTro]='DuocSi' OR [VaiTro]='KTV' OR [VaiTro]='ThuNgan' OR [VaiTro]='QuanTri');
GO
ALTER TABLE [dbo].[NoiTru] WITH CHECK ADD CONSTRAINT [CK__NoiTru__TrangTha__04E4BC85] CHECK ([TrangThai]='ChuyenKhoa' OR [TrangThai]='DaXuatVien' OR [TrangThai]='DangNam');
GO
ALTER TABLE [dbo].[NoiTru] WITH CHECK ADD CONSTRAINT [CK_NoiTru_NgayXuat] CHECK ([NgayXuatVien] IS NULL OR [NgayXuatVien]>=[NgayNhapVien]);
GO
ALTER TABLE [dbo].[Phong] WITH CHECK ADD CONSTRAINT [CK__Phong__LoaiPhong__26CFC035] CHECK ([LoaiPhong]='PHAU_THUAT' OR [LoaiPhong]='XET_NGHIEM' OR [LoaiPhong]='LUU_BENH' OR [LoaiPhong]='KHAM_BENH');
GO
ALTER TABLE [dbo].[TaiKhoan] WITH CHECK ADD CONSTRAINT [CK_TaiKhoan_VaiTro] CHECK ([VaiTro]='QuanLyNhanSu' OR [VaiTro]='BacSi' OR [VaiTro]='DieuDuong' OR [VaiTro]='LeTan' OR [VaiTro]='DuocSi' OR [VaiTro]='KTV' OR [VaiTro]='ThuNgan' OR [VaiTro]='QuanTri' OR [VaiTro]='BenhNhan');
GO
ALTER TABLE [dbo].[Thuoc] WITH CHECK ADD CONSTRAINT [CK__Thuoc__DonGiaBan__52593CB8] CHECK ([DonGiaBan]>=(0));
GO
ALTER TABLE [dbo].[Thuoc] WITH CHECK ADD CONSTRAINT [CK__Thuoc__TonKhoHie__5441852A] CHECK ([TonKhoHienTai]>=(0));
GO
ALTER TABLE [dbo].[YeuCauChuyenKhoa] WITH CHECK ADD CONSTRAINT [CK__YeuCauChu__LoaiY__3F115E1A] CHECK ([LoaiYeuCau]='HOI_CHAN' OR [LoaiYeuCau]='CHUYEN_KHOA');
GO
