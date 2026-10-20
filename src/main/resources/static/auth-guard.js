/**
 * MEDICARE HIS - Authentication & Role-Based Access Control (RBAC) System
 * Phân quyền chi tiết theo vai trò chuẩn y tế (UC12 RBAC)
 */
(function () {
    // 1. Ma trận phân quyền các phân hệ (Module Permission Matrix - Chuẩn 11 tác nhân y tế)
    const ROLE_PERMISSIONS = {
        'dashboard.html': ['QuanTri', 'ADMIN', 'GiamDoc', 'DIRECTOR'],
        'appointments.html': ['LeTan', 'RECEPTIONIST', 'BenhNhan', 'PATIENT'],
        'patients.html': ['BacSi', 'DOCTOR', 'LeTan', 'RECEPTIONIST', 'BenhNhan', 'PATIENT'],
        'doctors.html': ['QuanLyNhanSu', 'HR', 'LeTan', 'RECEPTIONIST'],
        'examination.html': ['BacSi', 'DOCTOR'],
        'referrals.html': ['BacSi', 'DOCTOR', 'TruongKhoa'],
        'laboratory.html': ['KTV', 'TECHNICIAN', 'BacSi', 'DOCTOR'],
        'pharmacy.html': ['DuocSi', 'PHARMACIST'],
        'inpatient.html': ['DieuDuong', 'NURSE'],
        'billing.html': ['ThuNgan', 'CASHIER', 'BenhNhan', 'PATIENT'],
        'settings.html': ['QuanTri', 'ADMIN', 'GiamDoc', 'DIRECTOR', 'BacSi', 'DOCTOR', 'LeTan', 'RECEPTIONIST', 'DuocSi', 'PHARMACIST', 'KTV', 'TECHNICIAN', 'DieuDuong', 'NURSE', 'ThuNgan', 'CASHIER', 'QuanLyNhanSu', 'HR']
    };

    // 2. Trang làm việc mặc định theo từng vai trò (Role Landing Pages)
    const ROLE_LANDING_PAGES = {
        'QuanTri': '/dashboard.html',
        'ADMIN': '/dashboard.html',
        'GiamDoc': '/dashboard.html',
        'DIRECTOR': '/dashboard.html',
        'QuanLyNhanSu': '/doctors.html',
        'HR': '/doctors.html',
        'BacSi': '/examination.html',
        'DOCTOR': '/examination.html',
        'ThuNgan': '/billing.html',
        'CASHIER': '/billing.html',
        'DuocSi': '/pharmacy.html',
        'PHARMACIST': '/pharmacy.html',
        'KTV': '/laboratory.html',
        'TECHNICIAN': '/laboratory.html',
        'DieuDuong': '/inpatient.html',
        'NURSE': '/inpatient.html',
        'LeTan': '/appointments.html',
        'RECEPTIONIST': '/appointments.html',
        'BenhNhan': '/appointments.html',
        'PATIENT': '/appointments.html'
    };

    // 3. Tên hiển thị & màu sắc nhận diện vai trò
    const ROLE_META = {
        'QuanTri': { name: 'Quản Trị Viên Hệ Thống (ADMIN)', short: 'Quản Trị', color: '#991b1b', bg: '#fee2e2', icon: 'fa-shield-halved' },
        'ADMIN': { name: 'Quản Trị Viên Hệ Thống (ADMIN)', short: 'Quản Trị', color: '#991b1b', bg: '#fee2e2', icon: 'fa-shield-halved' },
        'GiamDoc': { name: 'Ban Giám Đốc (DIRECTOR)', short: 'Ban Giám Đốc', color: '#1d4ed8', bg: '#dbeafe', icon: 'fa-building-columns' },
        'DIRECTOR': { name: 'Ban Giám Đốc (DIRECTOR)', short: 'Ban Giám Đốc', color: '#1d4ed8', bg: '#dbeafe', icon: 'fa-building-columns' },
        'QuanLyNhanSu': { name: 'Quản Lý Nhân Sự (HR MANAGER)', short: 'Nhân Sự', color: '#c026d3', bg: '#fae8ff', icon: 'fa-users-gear' },
        'HR': { name: 'Quản Lý Nhân Sự (HR MANAGER)', short: 'Nhân Sự', color: '#c026d3', bg: '#fae8ff', icon: 'fa-users-gear' },
        'BacSi': { name: 'Bác Sĩ Điều Trị (DOCTOR)', short: 'Bác Sĩ', color: '#0369a1', bg: '#e0f2fe', icon: 'fa-user-doctor' },
        'DOCTOR': { name: 'Bác Sĩ Điều Trị (DOCTOR)', short: 'Bác Sĩ', color: '#0369a1', bg: '#e0f2fe', icon: 'fa-user-doctor' },
        'ThuNgan': { name: 'Thu Ngân / Kế Toán Viện Phí', short: 'Thu Ngân', color: '#b45309', bg: '#fef3c7', icon: 'fa-cash-register' },
        'CASHIER': { name: 'Thu Ngân / Kế Toán Viện Phí', short: 'Thu Ngân', color: '#b45309', bg: '#fef3c7', icon: 'fa-cash-register' },
        'DuocSi': { name: 'Dược Sĩ Kho Dược (PHARMACIST)', short: 'Dược Sĩ', color: '#065f46', bg: '#d1fae5', icon: 'fa-pills' },
        'PHARMACIST': { name: 'Dược Sĩ Kho Dược (PHARMACIST)', short: 'Dược Sĩ', color: '#065f46', bg: '#d1fae5', icon: 'fa-pills' },
        'KTV': { name: 'Kỹ Thuật Viên Cận Lâm Sàng (CLS)', short: 'KTV Xét Nghiệm', color: '#0f766e', bg: '#ccfbf1', icon: 'fa-flask-vial' },
        'TECHNICIAN': { name: 'Kỹ Thuật Viên Cận Lâm Sàng (CLS)', short: 'KTV Xét Nghiệm', color: '#0f766e', bg: '#ccfbf1', icon: 'fa-flask-vial' },
        'DieuDuong': { name: 'Điều Dưỡng Nội Trú (NURSE)', short: 'Điều Dưỡng', color: '#7c3aed', bg: '#ede9fe', icon: 'fa-bed-pulse' },
        'NURSE': { name: 'Điều Dưỡng Nội Trú (NURSE)', short: 'Điều Dưỡng', color: '#7c3aed', bg: '#ede9fe', icon: 'fa-bed-pulse' },
        'LeTan': { name: 'Tiếp Đón / Lễ Tân (RECEPTIONIST)', short: 'Lễ Tân', color: '#4338ca', bg: '#e0e7ff', icon: 'fa-calendar-check' },
        'RECEPTIONIST': { name: 'Tiếp Đón / Lễ Tân (RECEPTIONIST)', short: 'Lễ Tân', color: '#4338ca', bg: '#e0e7ff', icon: 'fa-calendar-check' },
        'BenhNhan': { name: 'Bệnh Nhân (PATIENT)', short: 'Bệnh Nhân', color: '#0284c7', bg: '#e0f2fe', icon: 'fa-hospital-user' },
        'PATIENT': { name: 'Bệnh Nhân (PATIENT)', short: 'Bệnh Nhân', color: '#0284c7', bg: '#e0f2fe', icon: 'fa-hospital-user' }
    };

    // Session cookie được server kiểm tra; role header không được dùng để cấp quyền.
    const originalFetch = window.fetch;
    window.fetch = function (url, options = {}) {
        return originalFetch(url, options);
    };

    // 5. Kiểm tra quyền truy cập trang hiện tại
    const path = window.location.pathname;
    const currentPage = path.substring(path.lastIndexOf('/') + 1) || 'index.html';
    const publicPages = ['login.html', 'index.html', ''];

    if (publicPages.includes(currentPage)) {
        return;
    }

    const userJson = sessionStorage.getItem('authenticatedUser');
    if (!userJson) {
        // Chưa đăng nhập -> Chuyển hướng về login
        window.location.replace('/login.html?redirect=' + encodeURIComponent(currentPage));
        return;
    }

    let currentUser = null;
    try {
        currentUser = JSON.parse(userJson);
    } catch (e) {
        sessionStorage.removeItem('authenticatedUser');
        window.location.replace('/login.html');
        return;
    }

    const userRole = currentUser.vaiTro || 'BacSi';
    const allowedRoles = ROLE_PERMISSIONS[currentPage];

    // Hàm chuẩn hóa vai trò so sánh
    function checkPermission(role, allowedList) {
        if (!allowedList) return true;
        const normRole = role.toUpperCase();
        return allowedList.some(r => r.toUpperCase() === normRole);
    }

    const hasAccess = checkPermission(userRole, allowedRoles);

    if (!hasAccess) {
        window.location.replace(ROLE_LANDING_PAGES[userRole] || '/login.html');
        return;
    }

    // Xử lý giao diện khi DOM sẵn sàng
    document.addEventListener('DOMContentLoaded', function () {
        const meta = ROLE_META[userRole] || {
            name: userRole,
            short: userRole,
            color: '#0284c7',
            bg: '#e0f2fe',
            icon: 'fa-user'
        };

        // A. Cập nhật Badge người dùng trên Top Header
        const header = document.querySelector('.top-header');
        if (header) {
            // Kiểm tra xem đã có badge chưa
            let badgeContainer = document.getElementById('authHeaderBadge');
            if (!badgeContainer) {
                badgeContainer = document.createElement('div');
                badgeContainer.id = 'authHeaderBadge';
                badgeContainer.style.cssText = `
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    margin-left: 0;
                    margin-right: 16px;
                    background: #f8fafc;
                    border: 1px solid #e2e8f0;
                    padding: 6px 14px;
                    border-radius: 30px;
                `;

                badgeContainer.innerHTML = `
                    <div style="text-align: right; line-height: 1.25;">
                        <div style="font-weight: 700; font-size: 13.5px; color: #0f172a;">${currentUser.hoTen || currentUser.username}</div>
                        <div style="font-size: 11.5px; color: #64748b;">${meta.name}</div>
                    </div>
                    <span style="
                        background: ${meta.bg};
                        color: ${meta.color};
                        font-weight: 700;
                        font-size: 11.5px;
                        padding: 4px 10px;
                        border-radius: 20px;
                        display: inline-flex;
                        align-items: center;
                        gap: 5px;
                    ">
                        <i class="fa-solid ${meta.icon}"></i> ${meta.short}
                    </span>
                `;

                // Chèn trước nút Đăng xuất
                const logoutBtn = header.querySelector('.btn-logout');
                if (logoutBtn) {
                    logoutBtn.parentElement.insertBefore(badgeContainer, logoutBtn);
                } else {
                    header.appendChild(badgeContainer);
                }
            }

            // =========================================================================
            // C. TỰ ĐỘNG GẮN QUẢ CHUÔNG THÔNG BÁO CHO TẤT CẢ CÁC TRANG
            // Vị trí chuẩn: [ Quả Chuông 🔔 ] -> [ Tên & Vai Trò ] -> [ Đăng Xuất ]
            // =========================================================================
            if (!header.querySelector('.notification-wrapper')) {
                const notifWrapper = document.createElement('div');
                notifWrapper.className = 'notification-wrapper';
                notifWrapper.style.cssText = 'position:relative; cursor:pointer; margin-left:auto; margin-right:18px; display:inline-flex; align-items:center;';
                notifWrapper.innerHTML = `
                    <i class="fa-solid fa-bell" style="font-size:22px; color:#64748b; transition:0.2s;" onmouseover="this.style.color='#0284c7'" onmouseout="this.style.color='#64748b'"></i>
                    <span id="notifBadge" style="position:absolute; top:-7px; right:-9px; background:#ef4444; color:white; font-size:11px; font-weight:700; padding:2px 6px; border-radius:12px; display:none;">0</span>
                    
                    <!-- Dropdown Danh Sách Thông Báo -->
                    <div id="notifDropdown" style="display:none; position:absolute; top:38px; right:0; width:330px; background:#ffffff; border:1px solid #e2e8f0; border-radius:10px; box-shadow:0 10px 25px -5px rgba(0,0,0,0.15); z-index:99999; overflow:hidden; text-align:left;">
                        <div style="padding:12px 16px; border-bottom:1px solid #e2e8f0; font-weight:700; background:#f8fafc; font-size:13.5px; color:#0f172a; display:flex; justify-content:space-between; align-items:center;">
                            <span><i class="fa-solid fa-bell" style="color:#0284c7;"></i> Thông báo của bạn</span>
                        </div>
                        <div id="notifList" style="max-height:320px; overflow-y:auto; padding:0; font-size:13px;">
                            <div style="padding:18px; text-align:center; color:#64748b;">Đang tải thông báo...</div>
                        </div>
                    </div>
                `;

                // Bật/tắt dropdown khi click chuông
                notifWrapper.onclick = function(e) {
                    e.stopPropagation();
                    const dd = document.getElementById('notifDropdown');
                    if (dd) dd.style.display = dd.style.display === 'none' ? 'block' : 'none';
                };

                // Đóng dropdown khi click bất kỳ đâu ngoài chuông
                document.addEventListener('click', function(e) {
                    const dd = document.getElementById('notifDropdown');
                    if (dd && !notifWrapper.contains(e.target)) {
                        dd.style.display = 'none';
                    }
                });

                // Chèn chuông vào TRƯỚC khối Badge Tên & Vai trò: [Chuông 🔔] -> [Tên & Vai trò] -> [Đăng xuất]
                if (badgeContainer && badgeContainer.parentElement) {
                    badgeContainer.parentElement.insertBefore(notifWrapper, badgeContainer);
                } else {
                    const logoutBtn = header.querySelector('.btn-logout');
                    if (logoutBtn) {
                        logoutBtn.parentElement.insertBefore(notifWrapper, logoutBtn);
                    } else {
                        header.appendChild(notifWrapper);
                    }
                }

                // Kích hoạt logic lấy thông báo từ server
                setupGlobalNotifications();
            }
        }

        // B. Lọc Menu Sidebar theo quyền của vai trò (Dynamic Sidebar Filtering)
        const sidebarLinks = document.querySelectorAll('.sidebar-menu li a');
        sidebarLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (href) {
                const targetPage = href.replace('/', '').split('?')[0];
                const pageAllowed = ROLE_PERMISSIONS[targetPage];
                if (pageAllowed && !checkPermission(userRole, pageAllowed)) {
                    link.parentElement.remove();
                }
            }
        });

        // HÀM HELPER: Sửa thẻ text mà không làm mất cấu trúc icon của Sidebar mới
        function updateSidebarLink(href, iconClass, newLabel) {
            const link = document.querySelector(`.sidebar-menu a[href="${href}"]`);
            if (link) {
                // Tái tạo lại cấu trúc HTML để hỗ trợ hover thu gọn/mở rộng
                link.innerHTML = `<i class="${iconClass}"></i> <span class="link-text">${newLabel}</span>`;
            }
        }

        // Cập nhật text cho các role không phải Quản Trị
        if (userRole !== 'QuanTri' && userRole !== 'ADMIN') {
            updateSidebarLink('/settings.html', 'fa-solid fa-user-pen', 'Thông tin cá nhân');
            
            if (currentPage === 'settings.html') {
                document.querySelectorAll('.tab-btn:not(:first-child)').forEach(button => button.remove());
                document.querySelectorAll('.tab-content:not(#profileTab)').forEach(tab => tab.remove());
                const title = document.querySelector('.top-header .header-title h2');
                if (title) title.textContent = 'Thông tin cá nhân';
            }
        }

        // Cập nhật text cho Bệnh nhân
        if (userRole === 'BenhNhan' || userRole === 'PATIENT') {
            updateSidebarLink('/appointments.html', 'fa-solid fa-calendar-check', 'Lịch khám của tôi');
            updateSidebarLink('/patients.html', 'fa-solid fa-id-card', 'Hồ sơ cá nhân');
            updateSidebarLink('/billing.html', 'fa-solid fa-file-invoice-dollar', 'Hóa đơn của tôi');

            const titles = {
                'appointments.html': 'Đặt lịch khám trực tuyến',
                'patients.html': 'Hồ sơ cá nhân',
                'billing.html': 'Hóa đơn viện phí của tôi'
            };
            const title = document.querySelector('.top-header .header-title h2');
            if (title && titles[currentPage]) title.textContent = titles[currentPage];
        }

        // Cập nhật text cho Bác sĩ
        if (userRole === 'BacSi' || userRole === 'DOCTOR') {
            updateSidebarLink('/examination.html', 'fa-solid fa-stethoscope', 'Khám bệnh & Đơn thuốc');
            updateSidebarLink('/laboratory.html', 'fa-solid fa-flask-vial', 'Kết quả Cận lâm sàng (CLS)');
            
            // Link cài đặt đã được update ở trên (role != QuanTri)

            if (currentPage === 'patients.html') {
                document.querySelector('.btn-create-patient')?.remove();
                document.getElementById('patientModal')?.remove();
            }
        }
    });

    // Định nghĩa hàm logout toàn cục
    window.logout = async function () {
        try {
            await originalFetch('/api/v1/auth/logout', { method: 'POST' });
        } finally {
            sessionStorage.removeItem('authenticatedUser');
            window.location.href = '/login.html';
        }
    };

        // HÀM TOÀN CỤC: Gọi API lấy thông báo định kỳ cho mọi người dùng
    function setupGlobalNotifications() {
        let notifs = [];

        async function fetchNotifs() {
            try {
                const res = await originalFetch('/api/v1/thongbao/me');
                if (!res.ok) return;
                notifs = await res.json();
                
                const badge = document.getElementById('notifBadge');
                const list = document.getElementById('notifList');
                if (!badge || !list) return;

                const unread = notifs.filter(n => !n.daDoc).length;
                if (unread > 0) {
                    badge.style.display = 'block';
                    badge.innerText = unread > 9 ? '9+' : unread;
                } else {
                    badge.style.display = 'none';
                }

                if (notifs.length === 0) {
                    list.innerHTML = '<div style="padding:20px; text-align:center; color:#64748b;">Không có thông báo nào.</div>';
                    return;
                }

                list.innerHTML = notifs.map(n => `
                    <div onclick="markGlobalNotifAsRead(${n.maThongBao}, event)" style="padding:12px 16px; border-bottom:1px solid #f1f5f9; cursor:pointer; background:${n.daDoc ? '#ffffff' : '#f0f9ff'}; transition:0.2s;" onmouseover="this.style.background='#e0f2fe'" onmouseout="this.style.background='${n.daDoc ? '#ffffff' : '#f0f9ff'}'">
                        <div style="font-weight:700; color:#0f172a; margin-bottom:4px; font-size:13px;">${n.tieuDe}</div>
                        <div style="color:#475569; font-size:12.5px; line-height:1.4;">${n.noiDung}</div>
                        <div style="color:#94a3b8; font-size:11px; margin-top:6px;"><i class="fa-regular fa-clock"></i> ${new Date(n.ngayTao).toLocaleString('vi-VN')}</div>
                    </div>
                `).join('');
            } catch (err) {
                console.error("Lỗi lấy thông báo:", err);
            }
        }

        // Đánh dấu đã đọc khi người dùng bấm vào thông báo
        window.markGlobalNotifAsRead = async function(id, ev) {
            ev.stopPropagation();
            try {
                await originalFetch('/api/v1/thongbao/' + id + '/read', { method: 'PUT' });
                fetchNotifs();
            } catch (err) { console.error(err); }
        };

        // Chạy ngay khi mở trang và lặp lại mỗi 30s
        fetchNotifs();
        setInterval(fetchNotifs, 30000);
    }
})();