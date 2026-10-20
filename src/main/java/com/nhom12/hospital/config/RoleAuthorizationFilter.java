package com.nhom12.hospital.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import com.nhom12.hospital.entity.TaiKhoan;
import com.nhom12.hospital.repository.TaiKhoanRepository;
import com.nhom12.hospital.service.AuditLogService;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Optional;

@Component
public class RoleAuthorizationFilter extends OncePerRequestFilter {

    private final TaiKhoanRepository taiKhoanRepository;
    private final AuditLogService auditLogService;

    public RoleAuthorizationFilter(TaiKhoanRepository taiKhoanRepository, AuditLogService auditLogService) {
        this.taiKhoanRepository = taiKhoanRepository;
        this.auditLogService = auditLogService;
    }

    private String normalizeRole(String rawRole) {
        if (rawRole == null || rawRole.trim().isEmpty()) return "";
        String r = rawRole.trim().toUpperCase();
        if (r.contains("GIAMDOC") || r.contains("BGD") || r.contains("DIRECTOR") || r.contains("EXECUTIVE")) return "GiamDoc";
        if (r.contains("NHANSU") || r.contains("HR")) return "QuanLyNhanSu";
        if (r.contains("ADMIN") || r.contains("QUANTRI")) return "QuanTri";
        if (r.contains("DOC") || r.contains("BACSI")) return "BacSi";
        if (r.contains("CASHIER") || r.contains("THUNGAN")) return "ThuNgan";
        if (r.contains("PHARM") || r.contains("DUOC")) return "DuocSi";
        if (r.contains("RECEPT") || r.contains("LETAN") || r.contains("TIEPDON")) return "LeTan";
        if (r.contains("TECH") || r.contains("KTV") || r.contains("KYTHUAT")) return "KTV";
        if (r.contains("NURSE") || r.contains("DIEUDUONG")) return "DieuDuong";
        if (r.contains("BENHNHAN") || r.contains("PATIENT")) return "BenhNhan";
        return rawRole.trim();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();
        String method = request.getMethod().toUpperCase();
        boolean auditMutation = path.startsWith("/api/v1/")
            && !"GET".equals(method) && !"HEAD".equals(method) && !"OPTIONS".equals(method)
            && !"/api/v1/auth/login".equals(path)
            && !"/api/v1/auth/register".equals(path)
            && !"/api/v1/auth/forgot-password".equals(path)
            && !"/api/v1/auth/reset-password-otp".equals(path);
        String actor = null;
        String actorRole = null;

        try {
            if ("OPTIONS".equals(method) || "/api/v1/auth/login".equals(path)
                || "/api/v1/auth/register".equals(path)
                || "/api/v1/auth/forgot-password".equals(path)
                || "/api/v1/auth/reset-password-otp".equals(path)
                || ("GET".equals(method) && "/api/v1/khoa".equals(path))
                || ("GET".equals(method) && "/api/v1/nhanvien/doctors".equals(path))
                || ("GET".equals(method) && "/api/v1/lichhen/available-slots".equals(path))
                || !path.startsWith("/api/v1/")) {
                filterChain.doFilter(request, response);
                return;
            }

            HttpSession session = request.getSession(false);
            Object accountId = session == null ? null : session.getAttribute(SessionAttributes.ACCOUNT_ID);
            
            boolean isGuestAllowed = ("POST".equals(method) && "/api/v1/lichhen".equals(path));

            if (!(accountId instanceof Long id)) {
                if (isGuestAllowed) {
                    filterChain.doFilter(request, response);
                    return;
                }
                writeForbidden(response, "Yêu cầu đăng nhập.");
                return;
            }

            Optional<TaiKhoan> accountOpt = taiKhoanRepository.findById(id);
            if (accountOpt.isEmpty() || !Boolean.TRUE.equals(accountOpt.get().getTrangThai())) {
                if (session != null) {
                    session.invalidate();
                }
                writeForbidden(response, "Tài khoản không tồn tại hoặc đã bị khóa.");
                return;
            }

            TaiKhoan account = accountOpt.get();
            actor = account.getTenDangNhap();
            actorRole = account.getVaiTro();
            String role = normalizeRole(actorRole);
            request.setAttribute(SessionAttributes.USERNAME, actor);
            request.setAttribute(SessionAttributes.ACCOUNT_ID, account.getMaTaiKhoan());

            if ("/api/v1/auth/logout".equals(path)) {
                filterChain.doFilter(request, response);
                return;
            }

            if (path.startsWith("/api/v1/admin/audit-logs") && !"QuanTri".equals(role)) {
                writeForbidden(response, "Chỉ Admin được xem nhật ký truy cập.");
                return;
            }

            if (path.startsWith("/api/v1/dashboard/")
                    && !"QuanTri".equals(role) && !"GiamDoc".equals(role)) {
                writeForbidden(response, "Không có quyền xem báo cáo điều hành.");
                return;
            }

            if (path.startsWith("/api/v1/auth/")) {
                writeForbidden(response, "Endpoint xác thực không hợp lệ.");
                return;
            }

                if (path.startsWith("/api/v1/taikhoan")) {
                if (path.equals("/api/v1/taikhoan/change-password")
                        || (path.equals("/api/v1/taikhoan/unlinked") && ("QuanTri".equals(role) || "QuanLyNhanSu".equals(role)))) {
                    filterChain.doFilter(request, response);
                    return;
                }
                if (!"QuanTri".equals(role)) {
                    writeForbidden(response, "Chỉ Admin được quản lý tài khoản và vai trò.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

            if (path.startsWith("/api/v1/thongbao")) {
                filterChain.doFilter(request, response);
                return;
            }

            if ("BenhNhan".equals(role)) {
                boolean allowed = ("GET".equals(method) && "/api/v1/khoa".equals(path))
                        || ("GET".equals(method) && "/api/v1/nhanvien/doctors".equals(path))
                        || ("GET".equals(method) && "/api/v1/hoadon".equals(path))
                        || ("PUT".equals(method) && path.matches("/api/v1/hoadon/[^/]+/thanhtoan"))
                        || ("POST".equals(method) && "/api/v1/lichhen".equals(path))
                        || ("GET".equals(method) && "/api/v1/lichhen/me".equals(path))
                        || ("GET".equals(method) && "/api/v1/lichhen/available-slots".equals(path))
                        || ("PUT".equals(method) && path.matches("/api/v1/lichhen/[^/]+/(cancel|reschedule)"))
                        || ("GET".equals(method) || "POST".equals(method) || "PUT".equals(method))
                            && ("/api/v1/benhnhan/me".equals(path)
                                || "/api/v1/benhnhan/me/history".equals(path));
                if (!allowed) {
                    writeForbidden(response, "Bệnh nhân chỉ được truy cập hồ sơ, lịch hẹn và hóa đơn của mình.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

                        if ("QuanTri".equals(role)) {
                boolean allowed = "/api/v1/dashboard/stats".equals(path)
                        || "/api/v1/dashboard/report".equals(path)
                        || path.startsWith("/api/v1/admin/audit-logs")
                        || path.startsWith("/api/v1/khoa")
                        || path.startsWith("/api/v1/phong")
                        || path.startsWith("/api/v1/giuongbenh");
                if (!allowed) {
                    writeForbidden(response, "Admin không có quyền truy cập phân hệ nghiệp vụ này.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

            if ("GiamDoc".equals(role)) {
                boolean allowed = ("GET".equals(method)
                        && ("/api/v1/dashboard/stats".equals(path)
                        || "/api/v1/dashboard/report".equals(path)))
                        || ("GET".equals(method) && "/api/v1/nhanvien/me".equals(path))
                        || ("PUT".equals(method) && "/api/v1/nhanvien/me".equals(path));
                if (!allowed) {
                    writeForbidden(response, "Ban Giám Đốc chỉ được xem báo cáo và quản lý thông tin cá nhân.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

            if ("BacSi".equals(role)) {
                if (!isDoctorRequestAllowed(path, method)) {
                    writeForbidden(response, "Bác sĩ không có quyền thực hiện thao tác này.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

            if ("DieuDuong".equals(role)) {
                if (!isNurseRequestAllowed(path, method)) {
                    writeForbidden(response, "Điều dưỡng không có quyền thực hiện thao tác này.");
                    return;
                }
                filterChain.doFilter(request, response);
                return;
            }

            boolean isAllowed = true;
            String requiredRoleDesc = "";

            // 1. Phân hệ Khám bệnh & Kê đơn (4.3 Bác sĩ)
            if (path.startsWith("/api/v1/phieukham") && method.equals("POST")) {
                if (!"BacSi".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Bác Sĩ Điều Trị (DOCTOR)";
                }
            }
            // 2. Phân hệ Kho Dược: Nhập kho & Phát thuốc (4.5 Dược sĩ)
            else if ((path.startsWith("/api/v1/thuoc/nhapkho") || path.contains("/donthuoc/") && path.endsWith("/xuat")) && method.equals("POST")) {
                if (!"DuocSi".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Dược Sĩ Kho Dược (PHARMACIST)";
                }
            }
            // 3. Phân hệ Viện phí: Thu tiền & Đóng hóa đơn (4.6 Thu ngân, 4.1 Bệnh nhân thanh toán online)
            else if (path.startsWith("/api/v1/hoadon") && path.endsWith("/thanhtoan") && method.equals("PUT")) {
                if (!"ThuNgan".equals(role) && !"BenhNhan".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Thu Ngân (CASHIER) hoặc Bệnh Nhân (Online)";
                }
            }
            // 4. Phân hệ Cận lâm sàng: Nhập & trả kết quả xét nghiệm (4.4 KTV)
            else if (path.startsWith("/api/v1/cls") && path.endsWith("/ketqua") && method.equals("PUT")) {
                if (!"KTV".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Kỹ Thuật Viên Cận Lâm Sàng (KTV)";
                }
            }
            // 5. Phân hệ Giường nội trú: Tiếp nhận & Xuất viện (4.7 Điều dưỡng, 4.3 Bác sĩ)
            else if (path.startsWith("/api/v1/noitru") && (method.equals("POST") || method.equals("PUT"))) {
                if (!"DieuDuong".equals(role) && !"BacSi".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Điều Dưỡng Nội Trú (NURSE) hoặc Bác Sĩ";
                }
            }
            // 6. Phân hệ Quản lý nhân sự: Thêm/Sửa nhân sự & Phân công lịch trực (4.8 Quản lý nhân sự)
            else if (( (path.startsWith("/api/v1/nhanvien") && !path.equals("/api/v1/nhanvien/me")) || path.startsWith("/api/v1/lichtruc")) && (method.equals("POST") || method.equals("PUT") || method.equals("DELETE"))) {
                if (!"QuanLyNhanSu".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Quản Lý Nhân Sự (HR MANAGER)";
                }
            }
            // 7. Phân hệ Đặt lịch & Tiếp đón (4.2 Lễ tân, 4.1 Bệnh nhân, 4.3 Bác sĩ)
            else if (path.startsWith("/api/v1/lichhen") && (method.equals("POST") || method.equals("PUT"))) {
                if (!"LeTan".equals(role) && !"BenhNhan".equals(role) && !"BacSi".equals(role)) {
                    isAllowed = false;
                    requiredRoleDesc = "Tiếp Đón / Lễ Tân, Bác Sĩ hoặc Bệnh Nhân";
                }
            }
            // 8. Phân hệ Cấu hình hệ thống & Cấp tài khoản nhân sự (4.9 Quản trị viên)
            if (!isAllowed) {
                writeForbidden(response, "Vai trò " + role + " không có quyền thực hiện nghiệp vụ này. Yêu cầu: " + requiredRoleDesc);
                return;
            }

            filterChain.doFilter(request, response);
        } finally {
            if (auditMutation) {
                String eventType = "/api/v1/auth/logout".equals(path) ? "LOGOUT"
                        : path.startsWith("/api/v1/taikhoan") ? "ACCOUNT_CHANGE" : "API_WRITE";
                auditLogService.record(eventType, actor, actorRole, method, path,
                    response.getStatus(), request.getRemoteAddr(),
                    (String) request.getAttribute(SessionAttributes.AUDIT_DETAIL));
            }
        }
    }

    private void writeForbidden(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"success\":false,\"status\":403,\"message\":\"" + message + "\"}");
    }

        private boolean isDoctorRequestAllowed(String path, String method) {
        if ("GET".equals(method)) {
            return isPathOrChild(path, "/api/v1/benhnhan")
                    || isPathOrChild(path, "/api/v1/lichhen")
                    || isPathOrChild(path, "/api/v1/phieukham")
                    || isPathOrChild(path, "/api/v1/thuoc")
                    || "/api/v1/dichvucls".equals(path)
                    || isPathOrChild(path, "/api/v1/cls")
                    || "/api/v1/khoa".equals(path)
                    || "/api/v1/nhanvien/me".equals(path)
                    || "/api/v1/nhanvien/doctors".equals(path)
                    || "/api/v1/chuyenkhoa/me".equals(path) || isPathOrChild(path, "/api/v1/chuyenkhoa");
        }

        return ("POST".equals(method) && (isPathOrChild(path, "/api/v1/phieukham")
                    || "/api/v1/chuyenkhoa".equals(path)
                    || path.matches("^/api/v1/chuyenkhoa/.+$")
                    || path.matches("^/api/v1/lichhen/.+/start$")))
                || ("PUT".equals(method) && "/api/v1/nhanvien/me".equals(path));
    }

    private boolean isNurseRequestAllowed(String path, String method) {
        if ("GET".equals(method)) {
            return isPathOrChild(path, "/api/v1/khoa")
                    || isPathOrChild(path, "/api/v1/giuongbenh")
                    || isPathOrChild(path, "/api/v1/noitru")
                    || isPathOrChild(path, "/api/v1/chuyenkhoa")
                    || isPathOrChild(path, "/api/v1/benhnhan") // Cho phép xem thông tin bệnh nhân
                    || "/api/v1/nhanvien/me".equals(path);
        }
        
        return ("POST".equals(method) || "PUT".equals(method)) && 
               (isPathOrChild(path, "/api/v1/noitru") 
                || isPathOrChild(path, "/api/v1/chuyenkhoa")
                || isPathOrChild(path, "/api/v1/giuongbenh")
                || "/api/v1/nhanvien/me".equals(path));
    }

    private boolean isPathOrChild(String path, String basePath) {
        return path.equals(basePath) || path.startsWith(basePath + "/");
    }
}
