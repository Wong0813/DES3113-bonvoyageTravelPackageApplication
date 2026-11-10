# DES3113 - Bon Voyage / 智能旅游套餐预订管理平台

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=nodedotjs)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.x-000000?logo=express)](https://expressjs.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?logo=mysql)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](#english) | [中文说明](#chinese)

---

<a name="english"></a>
## 🌐 English

### Project Overview
**Bon Voyage** is a comprehensive, full-stack travel package management and booking platform developed for the **DES3113 Mobile Application Development** capstone project. Designed to connect tourists, travel agencies, and platform administrators, the ecosystem delivers a smooth tourism booking experience alongside operational tools for travel operators.

### Key Features by Role

#### 1. 🧳 Customer (Tourist)
* **Discover & Explore**: Search and filter curated travel packages by destination, price, duration, and categories.
* **Itinerary & Details**: Comprehensive package breakdowns with day-by-day travel itineraries and included services.
* **Booking & Checkout**: Streamlined reservation flow with date selection, passenger count, and discount voucher redemption.
* **Wishlist**: Save favorite travel destinations for future bookings.
* **Reviews & Ratings**: Post feedback and evaluate tour packages based on personal travel experiences.
* **Live In-App Chat**: Interactive direct communication channel with travel agencies.
* **Notifications**: Real-time push updates for booking confirmations, trip reminders, and platform promotions.

#### 2. 🏢 Travel Agent
* **Package Management**: Create, edit, publish, and archive travel packages and daily itineraries.
* **Booking Monitoring**: Track customer reservations, handle scheduling, and manage tour capacity.
* **Client Engagement**: Respond to direct customer inquiries via the integrated messaging interface.
* **Business Profile**: Manage agency credentials, contact channels, and branding.

#### 3. 🛡️ System Administrator
* **Analytics Dashboard**: Real-time business metrics tracking total revenue, active bookings, user growth, and popular destinations.
* **Account Moderation**: Manage and audit customer and agency accounts.
* **Promotions & Vouchers**: Issue promotional discount codes and platform vouchers.
* **Broadcast Center**: Dispatch system-wide announcements to all connected users.

### Tech Stack
* **Frontend Mobile Client:** Flutter, Dart (Material 3 Theme, Responsive Layouts)
* **Backend API Server:** Node.js, Express.js (RESTful Architecture)
* **Database:** MySQL / MariaDB (Relational schema with foreign key constraints)
* **Communication & Polling:** RESTful APIs with intelligent low-latency polling for live messaging

### System Architecture
```text
DES3113-bonvoyageTravelPackageApplication/
├── database/
│   └── schema.sql                  # Complete relational database DDL & initial seeders
├── server/
│   ├── server.js                   # Express.js REST API server & database connection pool
│   └── package.json                # Node.js backend dependencies
└── lib/
    ├── main.dart                   # Application entrypoint & role-based route dispatcher
    ├── models/                     # Data models (Package, Booking, Voucher, User, etc.)
    ├── screens/
    │   ├── admin/                  # Admin home, analytics dashboard, broadcast center
    │   ├── agent/                  # Travel agent management hub, package creation forms
    │   ├── customer/               # Tourist portal (explore, trips, wishlist, booking sheet)
    │   └── auth/                   # Multi-role authentication (login, registration)
    ├── services/                   # HTTP API client services connecting to backend
    └── utils/                      # Custom theme definitions (AppTheme) & UI constants
```

### Getting Started

#### 1. Database Setup
1. Launch your MySQL server (via XAMPP, Laragon, or standalone MySQL).
2. Create a database named `bonvoyage_db`.
3. Import the database schema:
   ```bash
   mysql -u root -p bonvoyage_db < database/schema.sql
   ```

#### 2. Backend Server Setup
```bash
cd server
npm install
# Configure database credentials inside server.js or .env
node server.js
```
The REST API server will run on `http://localhost:3000`.

#### 3. Flutter Application Setup
```bash
# In the project root directory
flutter pub get

# Ensure the backend endpoint in lib/services/api_client.dart points to your server IP
flutter run
```

---

<a name="chinese"></a>
## 🇨🇳 中文说明

### 项目简介
**Bon Voyage（一路顺风）** 是在 **DES3113 移动应用开发** 课程中构建的全栈多角色智能旅游套餐预订与管理平台。系统集成了移动端前端、Node.js RESTful 后端及 MySQL 关系型数据库，打通游客、旅行社及平台管理人员三方协同。

### 角色功能矩阵

| 角色 | 核心功能 |
| :--- | :--- |
| **游客 (Customer)** | 探索目的地与旅游套餐、每日行程详情查看、在线预订结算、优惠券抵扣、收藏夹、游后评价打分、在线客服沟通、消息通知中心 |
| **旅行社代理 (Agent)** | 旅游套餐与行程发布/编辑/管理、游客预订状态流转处理、游客即时在线答疑咨询、机构主页管理 |
| **平台管理员 (Admin)** | 全平台数据可视化大屏（流水、预订量、活跃度）、用户与旅行社账号审核、全员系统广播推送、优惠券与营销活动发布 |

### 技术架构
* **移动端前端：** Flutter (Dart) - 现代化自适应 UI 设计
* **后端服务端：** Node.js + Express.js RESTful API
* **数据存储：** MySQL 关系型数据库（含完整表关系约束）

### 运行步骤
1. **数据库初始化**：导入 `database/schema.sql` 到 MySQL 数据库。
2. **启动后端服务**：进入 `server` 目录执行 `npm install` 并通过 `node server.js` 启动 API 接口（默认监听 3000 端口）。
3. **启动移动端**：项目根目录执行 `flutter pub get`，配置目标服务 IP 后执行 `flutter run` 即可在手机或模拟器上运行。
