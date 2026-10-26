use QuanLyBenhVien
go

CREATE OR ALTER VIEW dbo.vw_Thuoc AS SELECT * FROM dbo.Thuoc;
GO

CREATE OR ALTER VIEW dbo.vw_PhieuNhapKho AS SELECT * FROM dbo.PhieuNhapKho;
GO

CREATE OR ALTER VIEW dbo.vw_ChiTietNhapKho AS SELECT * FROM dbo.ChiTietNhapKho;
GO

CREATE OR ALTER VIEW dbo.vw_HoaDon AS SELECT * FROM dbo.HoaDon;
GO

CREATE OR ALTER VIEW dbo.vw_ChiTietHoaDon AS SELECT * FROM dbo.ChiTietHoaDon;
GO