/* ======================================================================
   06_Security_Permissions.sql - RBAC System (Roles, Users, Permissions)
   ====================================================================== */
USE [QuanLyBenhVien];
GO

IF DATABASE_PRINCIPAL_ID(N'Role_QuanTri') IS NULL       CREATE ROLE [Role_QuanTri];
IF DATABASE_PRINCIPAL_ID(N'Role_QuanLyNhanSu') IS NULL  CREATE ROLE [Role_QuanLyNhanSu];
IF DATABASE_PRINCIPAL_ID(N'Role_BacSi') IS NULL         CREATE ROLE [Role_BacSi];
IF DATABASE_PRINCIPAL_ID(N'Role_DieuDuong') IS NULL     CREATE ROLE [Role_DieuDuong];
IF DATABASE_PRINCIPAL_ID(N'Role_LeTan') IS NULL         CREATE ROLE [Role_LeTan];
IF DATABASE_PRINCIPAL_ID(N'Role_DuocSi') IS NULL        CREATE ROLE [Role_DuocSi];
IF DATABASE_PRINCIPAL_ID(N'Role_KTV') IS NULL           CREATE ROLE [Role_KTV];
IF DATABASE_PRINCIPAL_ID(N'Role_ThuNgan') IS NULL       CREATE ROLE [Role_ThuNgan];
IF DATABASE_PRINCIPAL_ID(N'Role_BenhNhan') IS NULL      CREATE ROLE [Role_BenhNhan];
GO

-- 2. QUẢN TRỊ VIÊN
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.TaiKhoan   TO [Role_QuanTri];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Khoa       TO [Role_QuanTri];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Phong      TO [Role_QuanTri];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.GiuongBenh TO [Role_QuanTri];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ThongBao   TO [Role_QuanTri];
GRANT SELECT, INSERT                 ON dbo.AuditLog   TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_TaiKhoan   TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_Khoa       TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_Phong      TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_GiuongBenh TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_AuditLog   TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_ThongBao   TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_BenhNhan   TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_LichHen    TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_HoaDon     TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_NoiTru     TO [Role_QuanTri];
GRANT SELECT ON dbo.vw_Thuoc      TO [Role_QuanTri];
GRANT EXECUTE ON dbo.usp_TaiKhoan_Insert       TO [Role_QuanTri];
GRANT EXECUTE ON dbo.usp_TaiKhoan_Update       TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_Khoa_Save              TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_Khoa_ToggleStatus      TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_Phong_Save             TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_Phong_ToggleStatus     TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_GiuongBenh_Save        TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_GiuongBenh_ToggleStatus TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_ThongBao_Broadcast     TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_ThongBao_Create        TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead      TO [Role_QuanTri];
GRANT EXECUTE ON dbo.sp_TaoThongBaoNhacLich    TO [Role_QuanTri];
GRANT EXECUTE ON dbo.usp_Entity_Save           TO [Role_QuanTri];
GRANT EXECUTE ON dbo.usp_Entity_Delete         TO [Role_QuanTri];
DENY INSERT, UPDATE, DELETE ON dbo.PhieuKham TO [Role_QuanTri];
DENY INSERT, UPDATE, DELETE ON dbo.DonThuoc  TO [Role_QuanTri];
DENY INSERT, UPDATE, DELETE ON dbo.KetQuaCLS TO [Role_QuanTri];
GO

-- 3. QUẢN LÝ NHÂN SỰ
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NhanVien           TO [Role_QuanLyNhanSu];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.LichTruc           TO [Role_QuanLyNhanSu];
GRANT SELECT, INSERT, UPDATE         ON dbo.LichSuPhanCongKhoa TO [Role_QuanLyNhanSu];
GRANT SELECT, INSERT, UPDATE         ON dbo.LichSuTruongKhoa   TO [Role_QuanLyNhanSu];
GRANT SELECT, UPDATE                 ON dbo.Khoa               TO [Role_QuanLyNhanSu];
GRANT SELECT                         ON dbo.Phong              TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_NhanVien TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_LichTruc TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_Khoa     TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_Phong    TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_TaiKhoan TO [Role_QuanLyNhanSu];
GRANT SELECT ON dbo.vw_ThongBao TO [Role_QuanLyNhanSu];
GRANT EXECUTE ON dbo.usp_Entity_Save      TO [Role_QuanLyNhanSu];
GRANT EXECUTE ON dbo.usp_Entity_Delete    TO [Role_QuanLyNhanSu];
GRANT EXECUTE ON dbo.sp_ThongBao_Create   TO [Role_QuanLyNhanSu];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead TO [Role_QuanLyNhanSu];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.PhieuKham TO [Role_QuanLyNhanSu];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.DonThuoc  TO [Role_QuanLyNhanSu];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.KetQuaCLS TO [Role_QuanLyNhanSu];
GO

-- 4. BÁC SĨ ĐIỀU TRỊ
GRANT SELECT, INSERT, UPDATE ON dbo.PhieuKham        TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.DonThuoc         TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.KetQuaCLS        TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.YeuCauChuyenKhoa TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.LichHen          TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.HoaDon           TO [Role_BacSi];
GRANT SELECT, INSERT, UPDATE ON dbo.ChiTietHoaDon    TO [Role_BacSi];
GRANT SELECT ON dbo.vw_BenhNhan          TO [Role_BacSi];
GRANT SELECT ON dbo.vw_LichHen           TO [Role_BacSi];
GRANT SELECT ON dbo.vw_PhieuKham         TO [Role_BacSi];
GRANT SELECT ON dbo.vw_DonThuoc          TO [Role_BacSi];
GRANT SELECT ON dbo.vw_Thuoc             TO [Role_BacSi];
GRANT SELECT ON dbo.vw_DichVuCLS         TO [Role_BacSi];
GRANT SELECT ON dbo.vw_KetQuaCLS         TO [Role_BacSi];
GRANT SELECT ON dbo.vw_ChiTietKetQuaCLS  TO [Role_BacSi];
GRANT SELECT ON dbo.vw_Khoa              TO [Role_BacSi];
GRANT SELECT ON dbo.vw_NhanVien          TO [Role_BacSi];
GRANT SELECT ON dbo.vw_YeuCauChuyenKhoa  TO [Role_BacSi];
GRANT SELECT ON dbo.vw_NoiTru            TO [Role_BacSi];
GRANT SELECT ON dbo.vw_ThongBao          TO [Role_BacSi];
GRANT SELECT ON dbo.fn_TinhHangDoiKham   TO [Role_BacSi];
GRANT EXECUTE ON dbo.sp_TiepNhanBenhNhan                 TO [Role_BacSi];
GRANT EXECUTE ON dbo.fn_TinhTongTienThuocTheoPhieuKham   TO [Role_BacSi];
GRANT EXECUTE ON dbo.usp_Entity_Save                     TO [Role_BacSi];
GRANT EXECUTE ON dbo.sp_ThongBao_Create                  TO [Role_BacSi];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead                TO [Role_BacSi];
DENY DELETE ON dbo.BenhNhan  TO [Role_BacSi];
DENY DELETE ON dbo.HoaDon    TO [Role_BacSi];
DENY DELETE ON dbo.TaiKhoan  TO [Role_BacSi];
GO

-- 5. ĐIỀU DƯỠNG NỘI TRÚ
GRANT SELECT, INSERT, UPDATE ON dbo.NoiTru           TO [Role_DieuDuong];
GRANT SELECT, UPDATE         ON dbo.GiuongBenh       TO [Role_DieuDuong];
GRANT SELECT, UPDATE         ON dbo.YeuCauChuyenKhoa TO [Role_DieuDuong];
GRANT SELECT, INSERT, UPDATE ON dbo.HoaDon           TO [Role_DieuDuong];
GRANT SELECT, INSERT, UPDATE ON dbo.ChiTietHoaDon    TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_Khoa             TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_Phong            TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_GiuongBenh       TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_NoiTru           TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_BenhNhan         TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_PhieuKham        TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_YeuCauChuyenKhoa TO [Role_DieuDuong];
GRANT SELECT ON dbo.vw_ThongBao         TO [Role_DieuDuong];
GRANT EXECUTE ON dbo.sp_GiuongBenh_ToggleStatus TO [Role_DieuDuong];
GRANT EXECUTE ON dbo.usp_Entity_Save            TO [Role_DieuDuong];
GRANT EXECUTE ON dbo.sp_ThongBao_Create         TO [Role_DieuDuong];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead       TO [Role_DieuDuong];
DENY DELETE ON dbo.NoiTru    TO [Role_DieuDuong];
DENY DELETE ON dbo.BenhNhan  TO [Role_DieuDuong];
DENY DELETE ON dbo.PhieuKham TO [Role_DieuDuong];
GO

-- 6. LỄ TÂN / TIẾP ĐÓN
GRANT SELECT, INSERT, UPDATE ON dbo.BenhNhan TO [Role_LeTan];
GRANT SELECT, INSERT, UPDATE ON dbo.LichHen  TO [Role_LeTan];
GRANT SELECT ON dbo.vw_BenhNhan        TO [Role_LeTan];
GRANT SELECT ON dbo.vw_LichHen         TO [Role_LeTan];
GRANT SELECT ON dbo.vw_Khoa            TO [Role_LeTan];
GRANT SELECT ON dbo.vw_Phong           TO [Role_LeTan];
GRANT SELECT ON dbo.vw_NhanVien        TO [Role_LeTan];
GRANT SELECT ON dbo.vw_ThongBao        TO [Role_LeTan];
GRANT SELECT ON dbo.fn_TinhHangDoiKham TO [Role_LeTan];
GRANT EXECUTE ON dbo.usp_Entity_Save      TO [Role_LeTan];
GRANT EXECUTE ON dbo.sp_ThongBao_Create   TO [Role_LeTan];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead TO [Role_LeTan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.PhieuKham      TO [Role_LeTan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.DonThuoc       TO [Role_LeTan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.KetQuaCLS      TO [Role_LeTan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.ChiTietNhapKho TO [Role_LeTan];
GO

-- 7. DƯỢC SĨ KHO DƯỢC
GRANT SELECT, INSERT, UPDATE ON dbo.Thuoc          TO [Role_DuocSi];
GRANT SELECT, INSERT, UPDATE ON dbo.PhieuNhapKho   TO [Role_DuocSi];
GRANT SELECT, INSERT, UPDATE ON dbo.ChiTietNhapKho TO [Role_DuocSi];
GRANT SELECT, UPDATE         ON dbo.DonThuoc       TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_Thuoc          TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_DonThuoc       TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_PhieuNhapKho   TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_ChiTietNhapKho TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_PhieuKham      TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_BenhNhan       TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_NhanVien       TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_HoaDon         TO [Role_DuocSi];
GRANT SELECT ON dbo.vw_ThongBao       TO [Role_DuocSi];
GRANT EXECUTE ON dbo.fn_TinhTongTienThuocTheoPhieuKham TO [Role_DuocSi];
GRANT EXECUTE ON dbo.usp_Entity_Save                   TO [Role_DuocSi];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead              TO [Role_DuocSi];
DENY DELETE ON dbo.DonThuoc  TO [Role_DuocSi];
DENY DELETE ON dbo.HoaDon    TO [Role_DuocSi];
DENY DELETE ON dbo.PhieuKham TO [Role_DuocSi];
GO

-- 8. KỸ THUẬT VIÊN CLS
GRANT SELECT, UPDATE         ON dbo.KetQuaCLS        TO [Role_KTV];
GRANT SELECT, INSERT, UPDATE ON dbo.ChiTietKetQuaCLS TO [Role_KTV];
GRANT SELECT ON dbo.vw_KetQuaCLS        TO [Role_KTV];
GRANT SELECT ON dbo.vw_ChiTietKetQuaCLS TO [Role_KTV];
GRANT SELECT ON dbo.vw_DichVuCLS        TO [Role_KTV];
GRANT SELECT ON dbo.vw_PhieuKham        TO [Role_KTV];
GRANT SELECT ON dbo.vw_BenhNhan         TO [Role_KTV];
GRANT SELECT ON dbo.vw_NhanVien         TO [Role_KTV];
GRANT SELECT ON dbo.vw_ThongBao         TO [Role_KTV];
GRANT EXECUTE ON dbo.usp_Entity_Save      TO [Role_KTV];
GRANT EXECUTE ON dbo.sp_ThongBao_Create   TO [Role_KTV];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead TO [Role_KTV];
DENY INSERT, UPDATE, DELETE ON dbo.DonThuoc TO [Role_KTV];
DENY INSERT, UPDATE, DELETE ON dbo.HoaDon   TO [Role_KTV];
DENY INSERT, UPDATE, DELETE ON dbo.NoiTru   TO [Role_KTV];
GO

-- 9. THU NGÂN VIỆN PHÍ
GRANT SELECT, UPDATE ON dbo.HoaDon        TO [Role_ThuNgan];
GRANT SELECT         ON dbo.ChiTietHoaDon TO [Role_ThuNgan];
GRANT SELECT ON dbo.vw_HoaDon        TO [Role_ThuNgan];
GRANT SELECT ON dbo.vw_ChiTietHoaDon TO [Role_ThuNgan];
GRANT SELECT ON dbo.vw_BenhNhan      TO [Role_ThuNgan];
GRANT SELECT ON dbo.vw_PhieuKham     TO [Role_ThuNgan];
GRANT SELECT ON dbo.vw_ThongBao      TO [Role_ThuNgan];
GRANT EXECUTE ON dbo.fn_TinhTongTienThuocTheoPhieuKham TO [Role_ThuNgan];
GRANT EXECUTE ON dbo.usp_Entity_Save                   TO [Role_ThuNgan];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead              TO [Role_ThuNgan];
GRANT EXECUTE ON dbo.sp_ThanhToanHoaDon                TO [Role_ThuNgan];
DENY INSERT, UPDATE, DELETE ON dbo.PhieuKham TO [Role_ThuNgan];
DENY INSERT, UPDATE, DELETE ON dbo.DonThuoc  TO [Role_ThuNgan];
DENY INSERT, UPDATE, DELETE ON dbo.KetQuaCLS TO [Role_ThuNgan];
DENY INSERT, UPDATE, DELETE ON dbo.Thuoc     TO [Role_ThuNgan];
GO

-- 10. BỆNH NHÂN
GRANT SELECT, INSERT, UPDATE ON dbo.BenhNhan TO [Role_BenhNhan];
GRANT SELECT, INSERT, UPDATE ON dbo.LichHen  TO [Role_BenhNhan];
GRANT SELECT, UPDATE         ON dbo.HoaDon   TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_Khoa             TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_NhanVien         TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_BenhNhan         TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_LichHen          TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_PhieuKham        TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_DonThuoc         TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_KetQuaCLS        TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_ChiTietKetQuaCLS TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_HoaDon           TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_ChiTietHoaDon    TO [Role_BenhNhan];
GRANT SELECT ON dbo.vw_ThongBao         TO [Role_BenhNhan];
GRANT SELECT ON dbo.fn_TinhHangDoiKham  TO [Role_BenhNhan];
GRANT EXECUTE ON dbo.fn_TinhTongTienThuocTheoPhieuKham TO [Role_BenhNhan];
GRANT EXECUTE ON dbo.usp_Entity_Save                   TO [Role_BenhNhan];
GRANT EXECUTE ON dbo.sp_ThongBao_MarkRead              TO [Role_BenhNhan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.AuditLog       TO [Role_BenhNhan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.PhieuNhapKho   TO [Role_BenhNhan];
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.ChiTietNhapKho TO [Role_BenhNhan];
DENY INSERT, UPDATE, DELETE         ON dbo.PhieuKham      TO [Role_BenhNhan];
DENY INSERT, UPDATE, DELETE         ON dbo.DonThuoc       TO [Role_BenhNhan];
DENY INSERT, UPDATE, DELETE         ON dbo.KetQuaCLS      TO [Role_BenhNhan];
GO

-- 11. TẠO DATABASE USERS
IF DATABASE_PRINCIPAL_ID(N'usr_quantri') IS NULL      CREATE USER [usr_quantri]      WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_nhansu') IS NULL       CREATE USER [usr_nhansu]       WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_bacsi') IS NULL        CREATE USER [usr_bacsi]        WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_dieuduong') IS NULL    CREATE USER [usr_dieuduong]    WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_letan') IS NULL        CREATE USER [usr_letan]        WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_duocsi') IS NULL       CREATE USER [usr_duocsi]       WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_ktv') IS NULL          CREATE USER [usr_ktv]          WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_thungan') IS NULL      CREATE USER [usr_thungan]      WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_benhnhan') IS NULL     CREATE USER [usr_benhnhan]     WITHOUT LOGIN;
GO

ALTER ROLE [Role_QuanTri]      ADD MEMBER [usr_quantri];
ALTER ROLE [Role_QuanLyNhanSu] ADD MEMBER [usr_nhansu];
ALTER ROLE [Role_BacSi]        ADD MEMBER [usr_bacsi];
ALTER ROLE [Role_DieuDuong]    ADD MEMBER [usr_dieuduong];
ALTER ROLE [Role_LeTan]        ADD MEMBER [usr_letan];
ALTER ROLE [Role_DuocSi]       ADD MEMBER [usr_duocsi];
ALTER ROLE [Role_KTV]          ADD MEMBER [usr_ktv];
ALTER ROLE [Role_ThuNgan]      ADD MEMBER [usr_thungan];
ALTER ROLE [Role_BenhNhan]     ADD MEMBER [usr_benhnhan];
GO