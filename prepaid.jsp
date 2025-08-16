<%@ page import="java.sql.*, java.util.*, java.io.*, jakarta.servlet.http.*, java.security.MessageDigest, java.net.HttpURLConnection, java.net.URL" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page errorPage="error.jsp" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%!
// Configuration class to hold all constants
public static class Config {
    // Database configuration
    public static final String DB_URL = "jdbc:mysql://localhost:3306/prepaid_db?useSSL=false&serverTimezone=UTC";
    public static final String DB_USER = "root";
    public static final String DB_PASS = "root";
    
    // Razorpay configuration
    public static final String RAZORPAY_KEY_ID = "rzp_test_YOUR_KEY_ID";
    public static final String RAZORPAY_KEY_SECRET = "YOUR_RAZORPAY_SECRET";
    
    // Session timeout in seconds (30 minutes)
    public static final int SESSION_TIMEOUT = 1800;
}

// Database utility class - made static
public static class DBUtil {
    // Initialize database connection
    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(Config.DB_URL, Config.DB_USER, Config.DB_PASS);
            conn.setAutoCommit(true); // Enable auto-commit
            return conn;
        } catch (ClassNotFoundException e) {
            throw new SQLException("Database driver not found", e);
        }
    }
    
    // Close resources
    public static void closeQuietly(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                // Quietly handle the exception
            }
        }
    }
    
    public static void closeQuietly(Statement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                // Quietly handle the exception
            }
        }
    }
    
    public static void closeQuietly(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                // Quietly handle the exception
            }
        }
    }
    
    // Close all resources in proper order
    public static void closeAll(ResultSet rs, Statement stmt, Connection conn) {
        closeQuietly(rs);
        closeQuietly(stmt);
        closeQuietly(conn);
    }
}

// Security utility class - made static
public static class SecurityUtil {
    // Helper method to hash passwords with salt
    public static String hashPassword(String password) {
        try {
            String salt = "static_salt_should_be_replaced_with_user_specific_in_production";
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(salt.getBytes("UTF-8"));
            byte[] hash = md.digest(password.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("Password hashing failed", e);
        }
    }
    
    // Helper method to generate random transaction ID
    public static String generateTransactionId() {
        return "TXN" + System.currentTimeMillis() + (int)(Math.random() * 1000);
    }
    
    // Validate mobile number format
    public static boolean isValidMobile(String mobile) {
        return mobile != null && mobile.matches("^[6-9]\\d{9}$");
    }
    
    // Sanitize user input
    public static String sanitizeInput(String input) {
        if (input == null) return "";
        return input.replaceAll("<", "&lt;").replaceAll(">", "&gt;");
    }
}

// User session management - made static
public static class SessionUtil {
    // Helper method to check if user is logged in
    public static boolean isLoggedIn(HttpSession session) {
        if (session == null) return false;
        return session.getAttribute("user_id") != null;
    }
    
    // Helper method to check if user is admin
    public static boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        return "true".equals(session.getAttribute("is_admin"));
    }
    
    // Initialize user session
    public static void initUserSession(HttpSession session, int userId, String userName, boolean isAdmin) {
        session.setAttribute("user_id", userId);
        session.setAttribute("user_name", userName);
        session.setAttribute("is_admin", isAdmin ? "true" : "false");
        session.setMaxInactiveInterval(Config.SESSION_TIMEOUT);
    }
    
    // Clear user session
    public static void clearSession(HttpSession session) {
        if (session != null) {
            session.invalidate();
        }
    }
}

// Payment processor - made static
public static class PaymentProcessor {
    public static boolean processRazorpayPayment(String paymentId, double amount, String currency) {
        // In a real application, this would verify the payment with Razorpay API
        // For demo purposes, we'll just return true
        return true;
    }
}
%>

<%
// Set default response type and encoding
response.setContentType("text/html;charset=UTF-8");
response.setHeader("X-Content-Type-Options", "nosniff");
response.setHeader("X-Frame-Options", "DENY");
response.setHeader("X-XSS-Protection", "1; mode=block");

// Initialize connection
Connection conn = null;
try {
    conn = DBUtil.getConnection();
    
    // Handle form submissions
    String action = request.getParameter("action");
    
    if (action != null) {
        switch (action) {
            case "login":
                handleLogin(request, response, session);
                return;
                
            case "register":
                handleRegistration(request, response, session);
                return;
                
            case "logout":
                SessionUtil.clearSession(session);
                response.sendRedirect("prepaid.jsp");
                return;
                
            case "recharge":
                if (SessionUtil.isLoggedIn(session)) {
                    handleRecharge((Integer)session.getAttribute("user_id"), request, response, session);
                    return;
                }
                break;
                
            case "payment_callback":
                if (SessionUtil.isLoggedIn(session)) {
                    handlePaymentCallback((Integer)session.getAttribute("user_id"), request, response, session);
                    return;
                }
                break;
                
            case "check_balance":
                handleCheckBalance(request, response, session);
                return;
                
            case "auto_recharge":
                if (SessionUtil.isLoggedIn(session)) {
                    handleAutoRecharge((Integer)session.getAttribute("user_id"), request, response, session);
                    return;
                }
                break;
                
            case "cancel_auto_recharge":
                if (SessionUtil.isLoggedIn(session)) {
                    handleCancelAutoRecharge((Integer)session.getAttribute("user_id"), request, response, session);
                    return;
                }
                break;
                
            case "admin_save_plan":
                if (SessionUtil.isAdmin(session)) {
                    handleSavePlan(request, response, session);
                    return;
                }
                break;
                
            case "admin_delete_plan":
                if (SessionUtil.isAdmin(session)) {
                    handleDeletePlan(request, response, session);
                    return;
                }
                break;
                
            default:
                // No specific action, just continue to page rendering
                break;
        }
    }
} catch (SQLException e) {
    session.setAttribute("error", "Database error: " + e.getMessage());
    response.sendRedirect("prepaid.jsp");
    return;
} catch (Exception e) {
    session.setAttribute("error", "An unexpected error occurred: " + e.getMessage());
    response.sendRedirect("prepaid.jsp");
    return;
} finally {
    DBUtil.closeQuietly(conn);
}
%>

<%!
private void handleLogin(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    // Sanitize and get input parameters
    String email = SecurityUtil.sanitizeInput(request.getParameter("email"));
    String password = SecurityUtil.hashPassword(request.getParameter("password"));
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        // Get database connection
        conn = DBUtil.getConnection();
        
        // Prepare SQL query to find user
        String sql = "SELECT id, name, is_admin FROM users WHERE email = ? AND password = ?";
        stmt = conn.prepareStatement(sql);
        stmt.setString(1, email);
        stmt.setString(2, password);
        
        // Execute query
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            // Successful login
            int userId = rs.getInt("id");
            String userName = rs.getString("name");
            boolean isAdmin = rs.getBoolean("is_admin");
            
            // Initialize user session
            SessionUtil.initUserSession(session, userId, userName, isAdmin);
            session.setAttribute("message", "Login successful!");
            
            // Redirect to home page
            response.sendRedirect("prepaid.jsp");
        } else {
            // Failed login
            session.setAttribute("error", "Invalid email or password");
            response.sendRedirect("prepaid.jsp");
        }
    } finally {
        DBUtil.closeAll(rs, stmt, conn);
    }
}
%>

<%!
private void handleRegistration(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String name = SecurityUtil.sanitizeInput(request.getParameter("name"));
    String email = SecurityUtil.sanitizeInput(request.getParameter("email"));
    String mobile = SecurityUtil.sanitizeInput(request.getParameter("mobile"));
    String password = SecurityUtil.hashPassword(request.getParameter("password"));
    
    if (!SecurityUtil.isValidMobile(mobile)) {
        session.setAttribute("error", "Invalid mobile number format");
        response.sendRedirect("prepaid.jsp");
        return;
    }
    
    Connection conn = null;
    PreparedStatement checkStmt = null;
    ResultSet checkRs = null;
    PreparedStatement stmt = null;
    
    try {
        conn = DBUtil.getConnection();
        
        // Check if email already exists
        checkStmt = conn.prepareStatement("SELECT id FROM users WHERE email = ?");
        checkStmt.setString(1, email);
        checkRs = checkStmt.executeQuery();
        
        if (checkRs.next()) {
            session.setAttribute("error", "Email already registered");
        } else {
            stmt = conn.prepareStatement(
                "INSERT INTO users (name, email, mobile, password, is_admin, created_at) VALUES (?, ?, ?, ?, ?, NOW())");
            stmt.setString(1, name);
            stmt.setString(2, email);
            stmt.setString(3, mobile);
            stmt.setString(4, password);
            stmt.setBoolean(5, false);
            stmt.executeUpdate();
            
            session.setAttribute("message", "Registration successful! Please login.");
        }
    } finally {
        DBUtil.closeAll(checkRs, checkStmt, null);
        DBUtil.closeQuietly(stmt);
        DBUtil.closeQuietly(conn);
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handleRecharge(int userId, HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String mobile = SecurityUtil.sanitizeInput(request.getParameter("mobile"));
    String operator = SecurityUtil.sanitizeInput(request.getParameter("operator"));
    String circle = SecurityUtil.sanitizeInput(request.getParameter("circle"));
    String planId = SecurityUtil.sanitizeInput(request.getParameter("plan"));
    
    if (!SecurityUtil.isValidMobile(mobile)) {
        session.setAttribute("error", "Invalid mobile number format");
        response.sendRedirect("prepaid.jsp");
        return;
    }
    
    Connection conn = null;
    PreparedStatement planStmt = null;
    ResultSet planRs = null;
    PreparedStatement transStmt = null;
    
    try {
        conn = DBUtil.getConnection();
        
        // Get plan details
        planStmt = conn.prepareStatement("SELECT * FROM recharge_plans WHERE id = ?");
        planStmt.setString(1, planId);
        planRs = planStmt.executeQuery();
        
        if (planRs.next()) {
            double amount = planRs.getDouble("amount");
            String validity = planRs.getString("validity");
            String description = planRs.getString("description");
            
            // Generate transaction ID
            String transactionId = SecurityUtil.generateTransactionId();
            
            // Insert transaction as pending
            transStmt = conn.prepareStatement(
                "INSERT INTO transactions (user_id, transaction_id, mobile_number, operator, " +
                "circle, plan_id, amount, status, transaction_date) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())");
            transStmt.setInt(1, userId);
            transStmt.setString(2, transactionId);
            transStmt.setString(3, mobile);
            transStmt.setString(4, operator);
            transStmt.setString(5, circle);
            transStmt.setString(6, planId);
            transStmt.setDouble(7, amount);
            transStmt.executeUpdate();
            
            // Store transaction details for Razorpay
            session.setAttribute("razorpay_amount", (int)(amount * 100)); // in paise
            session.setAttribute("razorpay_order_id", transactionId);
            session.setAttribute("razorpay_plan_id", planId);
            session.setAttribute("razorpay_mobile", mobile);
            session.setAttribute("razorpay_operator", operator);
            session.setAttribute("razorpay_circle", circle);
            
            response.sendRedirect("prepaid.jsp?action=payment");
            return;
        } else {
            session.setAttribute("error", "Selected plan not found");
        }
    } finally {
        DBUtil.closeAll(planRs, planStmt, null);
        DBUtil.closeQuietly(transStmt);
        DBUtil.closeQuietly(conn);
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handlePaymentCallback(int userId, HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String paymentId = SecurityUtil.sanitizeInput(request.getParameter("razorpay_payment_id"));
    String orderId = SecurityUtil.sanitizeInput(request.getParameter("razorpay_order_id"));
    String signature = SecurityUtil.sanitizeInput(request.getParameter("razorpay_signature"));
    String planId = (String) session.getAttribute("razorpay_plan_id");
    String mobile = (String) session.getAttribute("razorpay_mobile");
    String operator = (String) session.getAttribute("razorpay_operator");
    String circle = (String) session.getAttribute("razorpay_circle");
    double amount = (Integer) session.getAttribute("razorpay_amount") / 100.0;
    
    // Verify payment
    boolean paymentSuccess = PaymentProcessor.processRazorpayPayment(paymentId, amount, "INR");
    
    if (paymentSuccess) {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = DBUtil.getConnection();
            stmt = conn.prepareStatement(
                "UPDATE transactions SET status = 'completed', payment_id = ?, " +
                "payment_date = NOW() WHERE transaction_id = ? AND user_id = ?");
            stmt.setString(1, paymentId);
            stmt.setString(2, orderId);
            stmt.setInt(3, userId);
            stmt.executeUpdate();
            
            session.setAttribute("message", "Recharge successful! Transaction ID: " + orderId);
            
            // Clear Razorpay session attributes
            session.removeAttribute("razorpay_amount");
            session.removeAttribute("razorpay_order_id");
            session.removeAttribute("razorpay_plan_id");
            session.removeAttribute("razorpay_mobile");
            session.removeAttribute("razorpay_operator");
            session.removeAttribute("razorpay_circle");
        } finally {
            DBUtil.closeAll(null, stmt, conn);
        }
    } else {
        session.setAttribute("error", "Payment verification failed");
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handleCheckBalance(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String mobile = SecurityUtil.sanitizeInput(request.getParameter("mobile"));
    String operator = SecurityUtil.sanitizeInput(request.getParameter("operator"));
    
    if (!SecurityUtil.isValidMobile(mobile)) {
        session.setAttribute("error", "Invalid mobile number format");
        response.sendRedirect("prepaid.jsp");
        return;
    }
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        conn = DBUtil.getConnection();
        stmt = conn.prepareStatement(
            "SELECT amount, validity, transaction_date FROM transactions " +
            "WHERE mobile_number = ? AND operator = ? AND status = 'completed' " +
            "ORDER BY transaction_date DESC LIMIT 1");
        stmt.setString(1, mobile);
        stmt.setString(2, operator);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            double amount = rs.getDouble("amount");
            String validity = rs.getString("validity");
            Date rechargeDate = rs.getDate("transaction_date");
            
            // Calculate remaining validity
            Calendar cal = Calendar.getInstance();
            cal.setTime(rechargeDate);
            String[] validityParts = validity.split(" ");
            int validityDays = Integer.parseInt(validityParts[0]);
            cal.add(Calendar.DAY_OF_MONTH, validityDays);
            Date expiryDate = cal.getTime();
            
            long diffDays = (expiryDate.getTime() - System.currentTimeMillis()) / (1000 * 60 * 60 * 24);
            diffDays = Math.max(0, diffDays);
            
            // Simulate data balance (50% to 100% of plan data remaining)
            String dataBalance = "N/A";
            if (validity.contains("GB")) {
                double dataTotal = Double.parseDouble(validity.split(" ")[0]);
                double dataRemaining = (0.5 + 0.5 * Math.random()) * dataTotal;
                dataBalance = String.format("%.2f GB", dataRemaining);
            }
            
            session.setAttribute("balanceInfo", 
                "Last Recharge: ₹" + amount + "<br>" +
                "Validity: " + validity + "<br>" +
                "Days Remaining: " + diffDays + "<br>" +
                "Data Balance: " + dataBalance);
        } else {
            session.setAttribute("error", "No recharge history found for this number");
        }
    } finally {
        DBUtil.closeAll(rs, stmt, conn);
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handleAutoRecharge(int userId, HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String mobile = SecurityUtil.sanitizeInput(request.getParameter("mobile"));
    String operator = SecurityUtil.sanitizeInput(request.getParameter("operator"));
    String planId = SecurityUtil.sanitizeInput(request.getParameter("plan"));
    String frequency = SecurityUtil.sanitizeInput(request.getParameter("frequency"));
    
    if (!SecurityUtil.isValidMobile(mobile)) {
        session.setAttribute("error", "Invalid mobile number format");
        response.sendRedirect("prepaid.jsp");
        return;
    }
    
    Connection conn = null;
    PreparedStatement autoStmt = null;
    
    try {
        conn = DBUtil.getConnection();
        autoStmt = conn.prepareStatement(
            "INSERT INTO auto_recharge (user_id, mobile_number, operator, plan_id, frequency, next_recharge_date) " +
            "VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 1 " + frequency + ")) " +
            "ON DUPLICATE KEY UPDATE plan_id = ?, frequency = ?, next_recharge_date = DATE_ADD(NOW(), INTERVAL 1 " + frequency + ")");
        autoStmt.setInt(1, userId);
        autoStmt.setString(2, mobile);
        autoStmt.setString(3, operator);
        autoStmt.setString(4, planId);
        autoStmt.setString(5, frequency);
        autoStmt.setString(6, planId);
        autoStmt.setString(7, frequency);
        autoStmt.executeUpdate();
        
        session.setAttribute("message", "Auto recharge set up successfully!");
    } finally {
        DBUtil.closeAll(null, autoStmt, conn);
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handleCancelAutoRecharge(int userId, HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    int autoRechargeId = Integer.parseInt(SecurityUtil.sanitizeInput(request.getParameter("id")));
    
    Connection conn = null;
    PreparedStatement stmt = null;
    
    try {
        conn = DBUtil.getConnection();
        stmt = conn.prepareStatement(
            "DELETE FROM auto_recharge WHERE id = ? AND user_id = ?");
        stmt.setInt(1, autoRechargeId);
        stmt.setInt(2, userId);
        stmt.executeUpdate();
        
        session.setAttribute("message", "Auto recharge cancelled successfully!");
    } finally {
        DBUtil.closeAll(null, stmt, conn);
    }
    
    response.sendRedirect("prepaid.jsp");
}
%>

<%!
private void handleSavePlan(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String id = SecurityUtil.sanitizeInput(request.getParameter("id"));
    String description = SecurityUtil.sanitizeInput(request.getParameter("description"));
    double amount = Double.parseDouble(SecurityUtil.sanitizeInput(request.getParameter("amount")));
    String validity = SecurityUtil.sanitizeInput(request.getParameter("validity"));
    String operator = SecurityUtil.sanitizeInput(request.getParameter("operator"));
    String circle = SecurityUtil.sanitizeInput(request.getParameter("circle"));
    String data = SecurityUtil.sanitizeInput(request.getParameter("data"));
    String talktime = SecurityUtil.sanitizeInput(request.getParameter("talktime"));
    
    Connection conn = null;
    PreparedStatement stmt = null;
    
    try {
        conn = DBUtil.getConnection();
        
        if (id == null || id.isEmpty()) {
            // Insert new plan
            stmt = conn.prepareStatement(
                "INSERT INTO recharge_plans (description, amount, validity, operator, circle, data, talktime) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)");
            stmt.setString(1, description);
            stmt.setDouble(2, amount);
            stmt.setString(3, validity);
            stmt.setString(4, operator);
            stmt.setString(5, circle);
            stmt.setString(6, data);
            stmt.setString(7, talktime);
        } else {
            // Update existing plan
            stmt = conn.prepareStatement(
                "UPDATE recharge_plans SET description = ?, amount = ?, validity = ?, " +
                "operator = ?, circle = ?, data = ?, talktime = ? WHERE id = ?");
            stmt.setString(1, description);
            stmt.setDouble(2, amount);
            stmt.setString(3, validity);
            stmt.setString(4, operator);
            stmt.setString(5, circle);
            stmt.setString(6, data);
            stmt.setString(7, talktime);
            stmt.setString(8, id);
        }
        
        stmt.executeUpdate();
        session.setAttribute("message", (id == null || id.isEmpty()) ? 
            "New recharge plan added successfully!" : "Recharge plan updated successfully!");
    } finally {
        DBUtil.closeAll(null, stmt, conn);
    }
    
    response.sendRedirect("prepaid.jsp?action=admin_manage_plans");
}
%>

<%!
private void handleDeletePlan(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
    throws SQLException, IOException {
    String id = SecurityUtil.sanitizeInput(request.getParameter("id"));
    
    Connection conn = null;
    PreparedStatement stmt = null;
    
    try {
        conn = DBUtil.getConnection();
        stmt = conn.prepareStatement("DELETE FROM recharge_plans WHERE id = ?");
        stmt.setString(1, id);
        stmt.executeUpdate();
        
        session.setAttribute("message", "Recharge plan deleted successfully!");
    } finally {
        DBUtil.closeAll(null, stmt, conn);
    }
    
    response.sendRedirect("prepaid.jsp?action=admin_manage_plans");
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="description" content="Prepaid Mobile Recharge Portal">
    <meta name="author" content="Your Name">
    
    <title>Prepaid Mobile Recharge</title>
    
    <!-- Favicon -->
    <link rel="icon" href="favicon.ico" type="image/x-icon">
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    
    <!-- Custom CSS -->
    <style>
        :root {
            --primary-color: #00a1e0;
            --secondary-color: #e3f2fd;
            --success-color: #28a745;
            --danger-color: #dc3545;
            --warning-color: #ffc107;
            --info-color: #17a2b8;
            --light-color: #f8f9fa;
            --dark-color: #343a40;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f7fa;
            color: #333;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .navbar-brand {
            font-weight: 700;
            color: var(--primary-color);
        }
        
        .card {
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            margin-bottom: 20px;
            border: none;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
        }
        
        .plan-card {
            cursor: pointer;
            border: 2px solid transparent;
        }
        
        .plan-card.selected {
            border-color: var(--primary-color);
            background-color: var(--secondary-color);
        }
        
        .plan-price {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary-color);
        }
        
        .tab-content {
            background-color: white;
            border-radius: 0 0 10px 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            border: 1px solid #dee2e6;
            border-top: none;
        }
        
        .nav-tabs .nav-link {
            border: none;
            color: #495057;
            font-weight: 600;
            padding: 12px 20px;
        }
        
        .nav-tabs .nav-link.active {
            color: var(--primary-color);
            background-color: white;
            border-bottom: 3px solid var(--primary-color);
        }
        
        .nav-tabs .nav-link:hover:not(.active) {
            color: var(--primary-color);
            border-bottom: 3px solid #dee2e6;
        }
        
        .btn-primary {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
        }
        
        .btn-primary:hover {
            background-color: #0088cc;
            border-color: #0088cc;
        }
        
        .payment-option {
            border: 2px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .payment-option.selected {
            border-color: var(--primary-color);
            background-color: var(--secondary-color);
        }
        
        .payment-option i {
            font-size: 24px;
            margin-bottom: 10px;
            color: var(--primary-color);
        }
        
        .transaction-history {
            max-height: 500px;
            overflow-y: auto;
        }
        
        .dashboard-card {
            text-align: center;
            padding: 20px;
            border-radius: 10px;
            color: white;
        }
        
        .dashboard-card i {
            font-size: 36px;
            margin-bottom: 15px;
        }
        
        .dashboard-card.users {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        
        .dashboard-card.recharges {
            background: linear-gradient(135deg, #ff9a9e 0%, #fad0c4 100%);
        }
        
        .dashboard-card.revenue {
            background: linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%);
        }
        
        .dashboard-card.plans {
            background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
            color: #333;
        }
        
        .admin-table th {
            background-color: var(--primary-color);
            color: white;
        }
        
        .form-control:focus, .form-select:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 0.25rem rgba(0, 161, 224, 0.25);
        }
        
        .toast {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1100;
        }
        
        .operator-logo {
            width: 30px;
            height: 30px;
            margin-right: 10px;
        }
        
        footer {
            margin-top: auto;
        }
        
        @media (max-width: 768px) {
            .dashboard-card {
                margin-bottom: 15px;
            }
            
            .payment-option {
                margin-bottom: 10px;
            }
        }
        
        /* Accessibility improvements */
        a:focus, button:focus {
            outline: 2px solid var(--primary-color);
            outline-offset: 2px;
        }
        
        /* Print styles */
        @media print {
            .no-print {
                display: none !important;
            }
            
            body {
                background-color: white;
                color: black;
            }
            
            .card {
                box-shadow: none;
                border: 1px solid #ddd;
            }
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-light bg-white shadow-sm no-print">
        <div class="container">
            <a class="navbar-brand" href="prepaid.jsp">
                <i class="fas fa-mobile-alt me-2"></i>Prepaid Recharge
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="prepaid.jsp">Home</a>
                    </li>
                    <% if (SessionUtil.isLoggedIn(session)) { %>
                    <li class="nav-item">
                        <a class="nav-link" href="prepaid.jsp?action=my_account">My Account</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="prepaid.jsp?action=transaction_history">History</a>
                    </li>
                    <% } %>
                    <% if (SessionUtil.isAdmin(session)) { %>
                    <li class="nav-item">
                        <a class="nav-link" href="prepaid.jsp?action=admin_dashboard">Admin</a>
                    </li>
                    <% } %>
                </ul>
                <ul class="navbar-nav">
                    <% if (SessionUtil.isLoggedIn(session)) { %>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-user-circle me-1"></i> <%= session.getAttribute("user_name") %>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
                            <li><a class="dropdown-item" href="prepaid.jsp?action=my_account"><i class="fas fa-user me-2"></i>My Account</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="prepaid.jsp?action=logout"><i class="fas fa-sign-out-alt me-2"></i>Logout</a></li>
                        </ul>
                    </li>
                    <% } else { %>
                    <li class="nav-item">
                        <a class="nav-link" href="#" data-bs-toggle="modal" data-bs-target="#loginModal">
                            <i class="fas fa-sign-in-alt me-1"></i> Login
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="btn btn-primary ms-2" href="#" data-bs-toggle="modal" data-bs-target="#registerModal">
                            <i class="fas fa-user-plus me-1"></i> Register
                        </a>
                    </li>
                    <% } %>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container my-5 flex-grow-1">
        <%-- Display messages --%>
        <% if (session.getAttribute("message") != null) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= session.getAttribute("message") %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("message"); %>
        <% } %>
        
        <% if (session.getAttribute("error") != null) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <%= session.getAttribute("error") %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("error"); %>
        <% } %>
        
        <% if (session.getAttribute("balanceInfo") != null) { %>
            <div class="alert alert-info alert-dismissible fade show" role="alert">
                <h5 class="alert-heading">Balance Information</h5>
                <%= session.getAttribute("balanceInfo") %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <% session.removeAttribute("balanceInfo"); %>
        <% } %>
        
        <%-- Payment Page --%>
        <% if ("payment".equals(request.getParameter("action"))) { %>
            <div class="row justify-content-center">
                <div class="col-md-8">
                    <div class="card">
                        <div class="card-header bg-primary text-white">
                            <h4 class="mb-0">Complete Payment</h4>
                        </div>
                        <div class="card-body">
                            <div class="text-center mb-4">
                                <h5>Order Summary</h5>
                                <p>Mobile: <%= session.getAttribute("razorpay_mobile") %></p>
                                <p>Operator: <%= session.getAttribute("razorpay_operator") %></p>
                                <p>Amount: ₹<%= (Integer)session.getAttribute("razorpay_amount") / 100 %></p>
                            </div>
                            
                            <form id="paymentForm" action="prepaid.jsp" method="POST">
                                <input type="hidden" name="action" value="payment_callback">
                                <input type="hidden" name="razorpay_payment_id" id="razorpay_payment_id">
                                <input type="hidden" name="razorpay_order_id" id="razorpay_order_id">
                                <input type="hidden" name="razorpay_signature" id="razorpay_signature">
                                
                                <div id="razorpay-container" class="text-center"></div>
                                
                                <div class="d-grid gap-2 mt-4">
                                    <button type="button" class="btn btn-outline-secondary" onclick="window.location.href='prepaid.jsp'">
                                        <i class="fas fa-times me-2"></i> Cancel Payment
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            
            <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
            <script>
                var options = {
                    "key": "<%= Config.RAZORPAY_KEY_ID %>",
                    "amount": "<%= session.getAttribute("razorpay_amount") %>",
                    "currency": "INR",
                    "name": "Prepaid Recharge",
                    "description": "Mobile Recharge Payment",
                    "order_id": "<%= session.getAttribute("razorpay_order_id") %>",
                    "handler": function(response) {
                        document.getElementById('razorpay_payment_id').value = response.razorpay_payment_id;
                        document.getElementById('razorpay_order_id').value = response.razorpay_order_id;
                        document.getElementById('razorpay_signature').value = response.razorpay_signature;
                        document.getElementById('paymentForm').submit();
                    },
                    "prefill": {
                        "name": "<%= SessionUtil.isLoggedIn(session) ? session.getAttribute("user_name") : "" %>",
                        "email": "",
                        "contact": ""
                    },
                    "theme": {
                        "color": "#00a1e0"
                    }
                };
                
                var rzp = new Razorpay(options);
                rzp.open();
                rzp.on('payment.failed', function(response) {
                    alert("Payment failed. Please try again.");
                    window.location.href = "prepaid.jsp";
                });
            </script>
        <% } %>

        <%-- Admin Dashboard --%>
        <% if (SessionUtil.isAdmin(session) && ("admin_dashboard".equals(request.getParameter("action")) || 
            "admin_manage_plans".equals(request.getParameter("action")) || 
            "admin_manage_users".equals(request.getParameter("action")))) { %>
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card dashboard-card users">
                        <i class="fas fa-users"></i>
                        <h5>Total Users</h5>
                        <%
                        try (Connection con1 = DBUtil.getConnection();
                             Statement stmt = con1.createStatement();
                             ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM users")) {
                            if (rs.next()) {
                                out.println("<h3>" + rs.getInt(1) + "</h3>");
                            }
                        } catch (SQLException e) {
                            out.println("<h3>Error</h3>");
                        }
                        %>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card dashboard-card recharges">
                        <i class="fas fa-mobile-alt"></i>
                        <h5>Today's Recharges</h5>
                        <%
                        try (Connection con2 = DBUtil.getConnection();
                             PreparedStatement stmt = con2.prepareStatement(
                                 "SELECT COUNT(*) FROM transactions WHERE DATE(transaction_date) = CURDATE()")) {
                            ResultSet rs = stmt.executeQuery();
                            if (rs.next()) {
                                out.println("<h3>" + rs.getInt(1) + "</h3>");
                            }
                        } catch (SQLException e) {
                            out.println("<h3>Error</h3>");
                        }
                        %>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card dashboard-card revenue">
                        <i class="fas fa-rupee-sign"></i>
                        <h5>Today's Revenue</h5>
                        <%
                        try (Connection con3 = DBUtil.getConnection();
                             PreparedStatement stmt = con3.prepareStatement(
                                 "SELECT SUM(amount) FROM transactions WHERE DATE(transaction_date) = CURDATE() AND status = 'completed'")) {
                            ResultSet rs = stmt.executeQuery();
                            if (rs.next()) {
                                double revenue = rs.getDouble(1);
                                out.println("<h3>₹" + (revenue > 0 ? String.format("%.2f", revenue) : "0") + "</h3>");
                            }
                        } catch (SQLException e) {
                            out.println("<h3>Error</h3>");
                        }
                        %>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card dashboard-card plans">
                        <i class="fas fa-list-alt"></i>
                        <h5>Active Plans</h5>
                        <%
                        try (Connection con4 = DBUtil.getConnection();
                             Statement stmt = con4.createStatement();
                             ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM recharge_plans")) {
                            if (rs.next()) {
                                out.println("<h3>" + rs.getInt(1) + "</h3>");
                            }
                        } catch (SQLException e) {
                            out.println("<h3>Error</h3>");
                        }
                        %>
                    </div>
                </div>
            </div>
            
            <ul class="nav nav-tabs mb-4">
                <li class="nav-item">
                    <a class="nav-link <%= "admin_dashboard".equals(request.getParameter("action")) ? "active" : "" %>" 
                       href="prepaid.jsp?action=admin_dashboard">Dashboard</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= "admin_manage_plans".equals(request.getParameter("action")) ? "active" : "" %>" 
                       href="prepaid.jsp?action=admin_manage_plans">Manage Plans</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= "admin_manage_users".equals(request.getParameter("action")) ? "active" : "" %>" 
                       href="prepaid.jsp?action=admin_manage_users">Manage Users</a>
                </li>
            </ul>
            
            <%-- Admin Dashboard Content --%>
            <% if ("admin_dashboard".equals(request.getParameter("action"))) { %>
                <div class="row">
                    <div class="col-md-8">
                        <div class="card">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0">Recent Transactions</h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>ID</th>
                                                <th>Mobile</th>
                                                <th>Amount</th>
                                                <th>Date</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                            try (Connection con5 = DBUtil.getConnection();
                                                 PreparedStatement stmt = con5.prepareStatement(
                                                     "SELECT t.transaction_id, t.mobile_number, t.amount, t.transaction_date, t.status, u.name " +
                                                     "FROM transactions t LEFT JOIN users u ON t.user_id = u.id " +
                                                     "ORDER BY t.transaction_date DESC LIMIT 10")) {
                                                ResultSet rs = stmt.executeQuery();
                                                while (rs.next()) {
                                            %>
                                            <tr>
                                                <td><%= rs.getString("transaction_id") %></td>
                                                <td><%= rs.getString("mobile_number") %></td>
                                                <td>₹<%= rs.getDouble("amount") %></td>
                                                <td><%= rs.getTimestamp("transaction_date") %></td>
                                                <td>
                                                    <span class="badge bg-<%= "completed".equals(rs.getString("status")) ? "success" : 
                                                                           "pending".equals(rs.getString("status")) ? "warning" : "danger" %>">
                                                        <%= rs.getString("status") %>
                                                    </span>
                                                </td>
                                            </tr>
                                            <%
                                                }
                                            } catch (SQLException e) {
                                                out.println("<tr><td colspan='5'>Error loading transactions</td></tr>");
                                            }
                                            %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0">Quick Stats</h5>
                            </div>
                            <div class="card-body">
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item d-flex justify-content-between align-items-center">
                                        Pending Payments
                                        <span class="badge bg-warning rounded-pill">
                                            <%
                                            try (Connection con6 = DBUtil.getConnection();
                                                 PreparedStatement stmt = con6.prepareStatement(
                                                     "SELECT COUNT(*) FROM transactions WHERE status = 'pending'")) {
                                                ResultSet rs = stmt.executeQuery();
                                                if (rs.next()) {
                                                    out.print(rs.getInt(1));
                                                }
                                            } catch (SQLException e) {
                                                out.print("Error");
                                            }
                                            %>
                                        </span>
                                    </li>
                                    <li class="list-group-item d-flex justify-content-between align-items-center">
                                        Active Auto Recharges
                                        <span class="badge bg-info rounded-pill">
                                            <%
                                            try (Connection con7 = DBUtil.getConnection();
                                                 PreparedStatement stmt = con7.prepareStatement(
                                                     "SELECT COUNT(*) FROM auto_recharge")) {
                                                ResultSet rs = stmt.executeQuery();
                                                if (rs.next()) {
                                                    out.print(rs.getInt(1));
                                                }
                                            } catch (SQLException e) {
                                                out.print("Error");
                                            }
                                            %>
                                        </span>
                                    </li>
                                    <li class="list-group-item d-flex justify-content-between align-items-center">
                                        Monthly Revenue
                                        <span class="badge bg-success rounded-pill">
                                            <%
                                            try (Connection con8 = DBUtil.getConnection();
                                                 PreparedStatement stmt = con8.prepareStatement(
                                                     "SELECT SUM(amount) FROM transactions WHERE status = 'completed' AND " +
                                                     "MONTH(transaction_date) = MONTH(CURRENT_DATE())")) {
                                                ResultSet rs = stmt.executeQuery();
                                                if (rs.next()) {
                                                    double revenue = rs.getDouble(1);
                                                    out.print("₹" + (revenue > 0 ? String.format("%.2f", revenue) : "0"));
                                                }
                                            } catch (SQLException e) {
                                                out.print("Error");
                                            }
                                            %>
                                        </span>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            
            <%-- Manage Plans --%>
            <% } else if ("admin_manage_plans".equals(request.getParameter("action"))) { %>
                <div class="card">
                    <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Manage Recharge Plans</h5>
                        <button class="btn btn-light btn-sm" data-bs-toggle="modal" data-bs-target="#addPlanModal">
                            <i class="fas fa-plus me-1"></i> Add New Plan
                        </button>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover admin-table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Description</th>
                                        <th>Amount</th>
                                        <th>Validity</th>
                                        <th>Operator</th>
                                        <th>Circle</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                    try (Connection con9 = DBUtil.getConnection();
                                         Statement stmt = con9.createStatement();
                                         ResultSet rs = stmt.executeQuery("SELECT * FROM recharge_plans ORDER BY operator, amount")) {
                                        while (rs.next()) {
                                    %>
                                    <tr>
                                        <td><%= rs.getString("id") %></td>
                                        <td><%= rs.getString("description") %></td>
                                        <td>₹<%= rs.getDouble("amount") %></td>
                                        <td><%= rs.getString("validity") %></td>
                                        <td><%= rs.getString("operator") %></td>
                                        <td><%= rs.getString("circle") %></td>
                                        <td>
                                            <button class="btn btn-sm btn-primary" 
                                                    onclick="editPlan('<%= rs.getString("id") %>', '<%= rs.getString("description") %>', 
                                                    '<%= rs.getDouble("amount") %>', '<%= rs.getString("validity") %>', 
                                                    '<%= rs.getString("operator") %>', '<%= rs.getString("circle") %>',
                                                    '<%= rs.getString("data") %>', '<%= rs.getString("talktime") %>')">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-sm btn-danger" 
                                                    onclick="confirmDeletePlan('<%= rs.getString("id") %>')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                    <%
                                        }
                                    } catch (SQLException e) {
                                        out.println("<tr><td colspan='7'>Error loading plans: " + e.getMessage() + "</td></tr>");
                                    }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Add/Edit Plan Modal -->
                <div class="modal fade" id="addPlanModal" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form id="planForm" method="post">
                                <input type="hidden" name="action" value="admin_save_plan">
                                <input type="hidden" name="id" id="planId">
                                <div class="modal-header">
                                    <h5 class="modal-title" id="planModalTitle">Add New Plan</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                                <div class="modal-body">
                                    <div class="mb-3">
                                        <label for="description" class="form-label">Description</label>
                                        <input type="text" class="form-control" id="description" name="description" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="amount" class="form-label">Amount (₹)</label>
                                        <input type="number" class="form-control" id="amount" name="amount" step="0.01" min="0" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="validity" class="form-label">Validity</label>
                                        <input type="text" class="form-control" id="validity" name="validity" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="operator" class="form-label">Operator</label>
                                        <select class="form-select" id="operator" name="operator" required>
                                            <option value="">Select Operator</option>
                                            <option value="airtel">Airtel</option>
                                            <option value="jio">Jio</option>
                                            <option value="vi">Vi</option>
                                            <option value="bsnl">BSNL</option>
                                        </select>
                                    </div>
                                    <div class="mb-3">
                                        <label for="circle" class="form-label">Circle</label>
                                        <select class="form-select" id="circle" name="circle" required>
                                            <option value="">Select Circle</option>
                                            <option value="delhi">Delhi</option>
                                            <option value="mumbai">Mumbai</option>
                                            <option value="kolkata">Kolkata</option>
                                            <option value="chennai">Chennai</option>
                                            <option value="bangalore">Bangalore</option>
                                            <option value="hyderabad">Hyderabad</option>
                                            <option value="punjab">Punjab</option>
                                            <option value="upw">UP West</option>
                                            <option value="upe">UP East</option>
                                        </select>
                                    </div>
                                    <div class="mb-3">
                                        <label for="data" class="form-label">Data (GB)</label>
                                        <input type="text" class="form-control" id="data" name="data" placeholder="e.g., 1.5GB/day">
                                    </div>
                                    <div class="mb-3">
                                        <label for="talktime" class="form-label">Talktime</label>
                                        <input type="text" class="form-control" id="talktime" name="talktime" placeholder="e.g., Unlimited">
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                    <button type="submit" class="btn btn-primary">Save Plan</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                
                <script>
                    function editPlan(id, description, amount, validity, operator, circle, data, talktime) {
                        document.getElementById('planModalTitle').innerText = 'Edit Plan';
                        document.getElementById('planId').value = id;
                        document.getElementById('description').value = description;
                        document.getElementById('amount').value = amount;
                        document.getElementById('validity').value = validity;
                        document.getElementById('operator').value = operator;
                        document.getElementById('circle').value = circle;
                        document.getElementById('data').value = data;
                        document.getElementById('talktime').value = talktime;
                        
                        var modal = new bootstrap.Modal(document.getElementById('addPlanModal'));
                        modal.show();
                    }
                    
                    function confirmDeletePlan(id) {
                        if (confirm('Are you sure you want to delete this plan?')) {
                            window.location.href = 'prepaid.jsp?action=admin_delete_plan&id=' + id;
                        }
                    }
                    
                    // Reset form when modal is hidden
                    document.getElementById('addPlanModal').addEventListener('hidden.bs.modal', function () {
                        document.getElementById('planModalTitle').innerText = 'Add New Plan';
                        document.getElementById('planForm').reset();
                        document.getElementById('planId').value = '';
                    });
                </script>
            
            <%-- Manage Users --%>
            <% } else if ("admin_manage_users".equals(request.getParameter("action"))) { %>
                <div class="card">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0">Manage Users</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover admin-table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Mobile</th>
                                        <th>Admin</th>
                                        <th>Joined</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                    try (Connection con10 = DBUtil.getConnection();
                                         Statement stmt = con10.createStatement();
                                         ResultSet rs = stmt.executeQuery("SELECT * FROM users ORDER BY id")) {
                                        while (rs.next()) {
                                    %>
                                    <tr>
                                        <td><%= rs.getInt("id") %></td>
                                        <td><%= rs.getString("name") %></td>
                                        <td><%= rs.getString("email") %></td>
                                        <td><%= rs.getString("mobile") %></td>
                                        <td>
                                            <% if (rs.getBoolean("is_admin")) { %>
                                                <span class="badge bg-success">Yes</span>
                                            <% } else { %>
                                                <span class="badge bg-secondary">No</span>
                                            <% } %>
                                        </td>
                                        <td><%= rs.getDate("created_at") %></td>
                                    </tr>
                                    <%
                                        }
                                    } catch (SQLException e) {
                                        out.println("<tr><td colspan='6'>Error loading users: " + e.getMessage() + "</td></tr>");
                                    }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            <% } %>
        
        <%-- My Account / Transaction History --%>
        <% } else if (SessionUtil.isLoggedIn(session) && ("my_account".equals(request.getParameter("action")) || "transaction_history".equals(request.getParameter("action")))) { %>
            <div class="row">
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-header bg-primary text-white">
                            <h5 class="mb-0">My Account</h5>
                        </div>
                        <div class="card-body text-center">
                            <div class="mb-3">
                                <i class="fas fa-user-circle fa-5x text-primary"></i>
                            </div>
                            <h4><%= session.getAttribute("user_name") %></h4>
                            <p class="text-muted">
                                <i class="fas fa-envelope me-2"></i>
                                <% 
                                try (Connection con11 = DBUtil.getConnection();
                                     PreparedStatement stmt = con11.prepareStatement(
                                         "SELECT email, mobile FROM users WHERE id = ?")) {
                                    stmt.setInt(1, (Integer) session.getAttribute("user_id"));
                                    ResultSet rs = stmt.executeQuery();
                                    if (rs.next()) {
                                        out.print(rs.getString("email"));
                                    }
                                } catch (SQLException e) {
                                    out.print("Error loading email");
                                }
                                %>
                            </p>
                            <p class="text-muted">
                                <i class="fas fa-mobile-alt me-2"></i>
                                <% 
                                try (Connection con12 = DBUtil.getConnection();
                                     PreparedStatement stmt = con12.prepareStatement(
                                         "SELECT mobile FROM users WHERE id = ?")) {
                                    stmt.setInt(1, (Integer) session.getAttribute("user_id"));
                                    ResultSet rs = stmt.executeQuery();
                                    if (rs.next()) {
                                        out.print(rs.getString("mobile"));
                                    }
                                } catch (SQLException e) {
                                    out.print("Error loading mobile");
                                }
                                %>
                            </p>
                            <hr>
                            <a href="prepaid.jsp?action=transaction_history" class="btn btn-outline-primary">
                                <i class="fas fa-history me-2"></i> View History
                            </a>
                        </div>
                    </div>
                    
                    <%-- Auto Recharges --%>
                    <div class="card mt-4">
                        <div class="card-header bg-primary text-white">
                            <h5 class="mb-0">My Auto Recharges</h5>
                        </div>
                        <div class="card-body">
                            <%
                            int userId = (Integer) session.getAttribute("user_id");
                            try (Connection con14 = DBUtil.getConnection();
                                 PreparedStatement stmt = con14.prepareStatement(
                                     "SELECT ar.id, ar.mobile_number, ar.operator, ar.frequency, ar.next_recharge_date, " +
                                     "rp.description, rp.amount FROM auto_recharge ar " +
                                     "JOIN recharge_plans rp ON ar.plan_id = rp.id " +
                                     "WHERE ar.user_id = ?")) {
                                stmt.setInt(1, userId);
                                ResultSet rs = stmt.executeQuery();
                                
                                if (!rs.isBeforeFirst()) {
                                    out.println("<p class='text-muted'>No auto recharges set up yet.</p>");
                                } else {
                                    while (rs.next()) {
                            %>
                            <div class="mb-3 p-3 border rounded">
                                <div class="d-flex justify-content-between">
                                    <h6><%= rs.getString("mobile_number") %></h6>
                                    <span class="badge bg-info"><%= rs.getString("operator") %></span>
                                </div>
                                <p class="mb-1"><%= rs.getString("description") %></p>
                                <p class="mb-1"><strong>₹<%= rs.getDouble("amount") %></strong></p>
                                <p class="mb-1">
                                    <small class="text-muted">
                                        <%= rs.getString("frequency").toLowerCase() %> recharge
                                        (Next: <%= rs.getDate("next_recharge_date") %>)
                                    </small>
                                </p>
                                <div class="text-end">
                                    <button class="btn btn-sm btn-danger" 
                                            onclick="if(confirm('Cancel this auto recharge?')) { window.location.href='prepaid.jsp?action=cancel_auto_recharge&id=<%= rs.getInt("id") %>'; }">
                                        <i class="fas fa-times"></i> Cancel
                                    </button>
                                </div>
                            </div>
                            <%
                                    }
                                }
                            } catch (SQLException e) {
                                out.println("<p class='text-danger'>Error loading auto recharges</p>");
                            }
                            %>
                        </div>
                    </div>
                </div>
                
                <div class="col-md-8">
                    <%-- Transaction History --%>
                    <div class="card">
                        <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                            <h5 class="mb-0">Transaction History</h5>
                            <div>
                                <button class="btn btn-light btn-sm" onclick="window.print()">
                                    <i class="fas fa-print me-1"></i> Print
                                </button>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Date</th>
                                            <th>Transaction ID</th>
                                            <th>Mobile</th>
                                            <th>Operator</th>
                                            <th>Amount</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                        try (Connection connn = DBUtil.getConnection();
                                             PreparedStatement stmt = connn.prepareStatement(
                                                 "SELECT t.transaction_id, t.mobile_number, t.operator, t.amount, " +
                                                 "t.transaction_date, t.status, rp.description " +
                                                 "FROM transactions t LEFT JOIN recharge_plans rp ON t.plan_id = rp.id " +
                                                 "WHERE t.user_id = ? ORDER BY t.transaction_date DESC")) {
                                            stmt.setInt(1, userId);
                                            ResultSet rs = stmt.executeQuery();
                                            
                                            if (!rs.isBeforeFirst()) {
                                                out.println("<tr><td colspan='6'>No transactions found</td></tr>");
                                            } else {
                                                while (rs.next()) {
                                        %>
                                        <tr>
                                            <td><%= rs.getTimestamp("transaction_date") %></td>
                                            <td><%= rs.getString("transaction_id") %></td>
                                            <td><%= rs.getString("mobile_number") %></td>
                                            <td><%= rs.getString("operator") %></td>
                                            <td>₹<%= rs.getDouble("amount") %></td>
                                            <td>
                                                <span class="badge bg-<%= "completed".equals(rs.getString("status")) ? "success" : 
                                                                       "pending".equals(rs.getString("status")) ? "warning" : "danger" %>">
                                                    <%= rs.getString("status") %>
                                                </span>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        } catch (SQLException e) {
                                            out.println("<tr><td colspan='6'>Error loading transactions</td></tr>");
                                        }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        
        <%-- Main Recharge Page --%>
        <% } else { %>
            <div class="container-fluid">
                <div class="row g-3">
                    <!-- Left Column (Main Content) -->
                    <div class="col-lg-8">
                        <div class="card">
                            <div class="card-header bg-primary text-white p-2">
                                <ul class="nav nav-tabs card-header-tabs" id="rechargeTabs" role="tablist">
                                    <li class="nav-item" role="presentation">
                                        <button class="nav-link active" id="recharge-tab" data-bs-toggle="tab" 
                                            data-bs-target="#recharge" type="button" role="tab" aria-controls="recharge" 
                                            aria-selected="true">
                                            <i class="fas fa-mobile-alt me-2"></i> Recharge
                                        </button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button class="nav-link" id="balance-tab" data-bs-toggle="tab" 
                                            data-bs-target="#balance" type="button" role="tab" aria-controls="balance" 
                                            aria-selected="false">
                                            <i class="fas fa-wallet me-2"></i> Check Balance
                                        </button>
                                    </li>
                                    <% if (SessionUtil.isLoggedIn(session)) { %>
                                    <li class="nav-item" role="presentation">
                                        <button class="nav-link" id="auto-tab" data-bs-toggle="tab" 
                                            data-bs-target="#auto" type="button" role="tab" aria-controls="auto" 
                                            aria-selected="false">
                                            <i class="fas fa-sync-alt me-2"></i> Auto Recharge
                                        </button>
                                    </li>
                                    <% } %>
                                </ul>
                            </div>
                            
                            <div class="card-body">
                                <div class="tab-content" id="rechargeTabsContent">
                                    <!-- Recharge Tab -->
                                    <div class="tab-pane fade show active" id="recharge" role="tabpanel" 
                                        aria-labelledby="recharge-tab">
                                        <form id="rechargeForm" method="post" class="needs-validation" novalidate>
                                            <input type="hidden" name="action" value="recharge">
                                            
                                            <div class="row g-3 mb-4">
                                                <div class="col-md-6">
                                                    <label for="mobile" class="form-label">Mobile Number</label>
                                                    <input type="tel" class="form-control" id="mobile" name="mobile" 
                                                           pattern="[6-9][0-9]{9}" required 
                                                           placeholder="Enter 10 digit mobile number">
                                                    <div class="invalid-feedback">
                                                        Please enter a valid 10-digit mobile number
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <label for="operator" class="form-label">Operator</label>
                                                    <select class="form-select" id="operator" name="operator" required>
                                                        <option value="" selected disabled>Select Operator</option>
                                                        <option value="airtel">Airtel</option>
                                                        <option value="jio">Jio</option>
                                                        <option value="vi">Vi</option>
                                                        <option value="bsnl">BSNL</option>
                                                    </select>
                                                    <div class="invalid-feedback">
                                                        Please select an operator
                                                    </div>
                                                </div>
                                                
                                                <div class="col-12">
                                                    <label for="circle" class="form-label">Circle</label>
                                                    <select class="form-select" id="circle" name="circle" required>
                                                        <option value="" selected disabled>Select Circle</option>
                                                        <option value="delhi">Delhi</option>
                                                        <option value="mumbai">Mumbai</option>
                                                        <option value="kolkata">Kolkata</option>
                                                        <option value="chennai">Chennai</option>
                                                        <option value="bangalore">Bangalore</option>
                                                        <option value="hyderabad">Hyderabad</option>
                                                        <option value="punjab">Punjab</option>
                                                        <option value="upw">UP West</option>
                                                        <option value="upe">UP East</option>
                                                    </select>
                                                    <div class="invalid-feedback">
                                                        Please select a circle
                                                    </div>
                                                </div>
                                            </div>

                                            <h5 class="mt-4 mb-3">Select Plan</h5>
                                            <div class="row g-3" id="plansContainer">
                                                <%
                                                String operatorFilter = request.getParameter("operator");
                                                String circleFilter = request.getParameter("circle");
                                                boolean plansFound = false;
                                                
                                                try (Connection co = DBUtil.getConnection()) {
                                                    String sql = "SELECT * FROM recharge_plans WHERE 1=1";
                                                    
                                                    if (operatorFilter != null && !operatorFilter.isEmpty()) {
                                                        sql += " AND operator = ?";
                                                    }
                                                    if (circleFilter != null && !circleFilter.isEmpty()) {
                                                        sql += " AND circle = ?";
                                                    }
                                                    
                                                    sql += " ORDER BY amount ASC";
                                                    
                                                    PreparedStatement stmt = conn.prepareStatement(sql);
                                                    int paramIndex = 1;
                                                    
                                                    if (operatorFilter != null && !operatorFilter.isEmpty()) {
                                                        stmt.setString(paramIndex++, operatorFilter);
                                                    }
                                                    if (circleFilter != null && !circleFilter.isEmpty()) {
                                                        stmt.setString(paramIndex, circleFilter);
                                                    }
                                                    
                                                    ResultSet rs = stmt.executeQuery();
                                                    
                                                    while (rs.next()) {
                                                        plansFound = true;
                                                        String id = rs.getString("id");
                                                        String desc = rs.getString("description");
                                                        double amount = rs.getDouble("amount");
                                                        String validity = rs.getString("validity");
                                                        String operator = rs.getString("operator");
                                                        String data = rs.getString("data");
                                                        String talktime = rs.getString("talktime");
                                                %>
                                                <div class="col-md-6">
                                                    <div class="card plan-card h-100" onclick="selectPlan(this, '<%= id %>')" 
                                                        role="button" tabindex="0" aria-label="Select <%= desc %> plan">
                                                        <div class="card-body">
                                                            <div class="d-flex justify-content-between align-items-start">
                                                                <div class="plan-price">₹<%= String.format("%.2f", amount) %></div>
                                                                <span class="badge bg-primary"><%= operator %></span>
                                                            </div>
                                                            <h6 class="card-title mt-2"><%= desc %></h6>
                                                            <p class="card-text mb-1"><small>Validity: <%= validity %></small></p>
                                                            <% if (data != null && !data.isEmpty()) { %>
                                                                <p class="card-text mb-1"><small>Data: <%= data %></small></p>
                                                            <% } %>
                                                            <% if (talktime != null && !talktime.isEmpty()) { %>
                                                                <p class="card-text mb-1"><small>Talktime: <%= talktime %></small></p>
                                                            <% } %>
                                                        </div>
                                                    </div>
                                                </div>
                                                <%
                                                    }
                                                    
                                                    if (!plansFound) {
                                                        // Show all plans if no filtered plans found
                                                        stmt = conn.prepareStatement("SELECT * FROM recharge_plans ORDER BY amount ASC");
                                                        rs = stmt.executeQuery();
                                                        
                                                        while (rs.next()) {
                                                            String id = rs.getString("id");
                                                            String desc = rs.getString("description");
                                                            double amount = rs.getDouble("amount");
                                                            String validity = rs.getString("validity");
                                                            String operator = rs.getString("operator");
                                                            String data = rs.getString("data");
                                                            String talktime = rs.getString("talktime");
                                                %>
                                                <div class="col-md-6">
                                                    <div class="card plan-card h-100" onclick="selectPlan(this, '<%= id %>')" 
                                                        role="button" tabindex="0" aria-label="Select <%= desc %> plan">
                                                        <div class="card-body">
                                                            <div class="d-flex justify-content-between align-items-start">
                                                                <div class="plan-price">₹<%= String.format("%.2f", amount) %></div>
                                                                <span class="badge bg-primary"><%= operator %></span>
                                                            </div>
                                                            <h6 class="card-title mt-2"><%= desc %></h6>
                                                            <p class="card-text mb-1"><small>Validity: <%= validity %></small></p>
                                                            <% if (data != null && !data.isEmpty()) { %>
                                                                <p class="card-text mb-1"><small>Data: <%= data %></small></p>
                                                            <% } %>
                                                            <% if (talktime != null && !talktime.isEmpty()) { %>
                                                                <p class="card-text mb-1"><small>Talktime: <%= talktime %></small></p>
                                                            <% } %>
                                                        </div>
                                                    </div>
                                                </div>
                                                <%
                                                        }
                                                    }
                                                } catch (SQLException e) {
                                                    out.println("<div class='col-12'><div class='alert alert-danger'>Error loading plans: " + 
                                                        SecurityUtil.sanitizeInput(e.getMessage()) + "</div></div>");
                                                }
                                                %>
                                            </div>
                                            <input type="hidden" id="selectedPlan" name="plan" required>
                                            
                                            <div class="d-grid mt-4">
                                                <button type="submit" class="btn btn-primary btn-lg py-3">
                                                    <i class="fas fa-bolt me-2"></i> Proceed to Recharge
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                    
                                    <!-- Check Balance Tab -->
                                    <div class="tab-pane fade" id="balance" role="tabpanel" aria-labelledby="balance-tab">
                                        <form id="balanceForm" method="post" class="needs-validation" novalidate>
                                            <input type="hidden" name="action" value="check_balance">
                                            
                                            <div class="row g-3">
                                                <div class="col-md-6">
                                                    <label for="balMobile" class="form-label">Mobile Number</label>
                                                    <input type="tel" class="form-control" id="balMobile" name="mobile" 
                                                           pattern="[6-9][0-9]{9}" required 
                                                           placeholder="Enter 10 digit mobile number">
                                                    <div class="invalid-feedback">
                                                        Please enter a valid 10-digit mobile number
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <label for="balOperator" class="form-label">Operator</label>
                                                    <select class="form-select" id="balOperator" name="operator" required>
                                                        <option value="" selected disabled>Select Operator</option>
                                                        <option value="airtel">Airtel</option>
                                                        <option value="jio">Jio</option>
                                                        <option value="vi">Vi</option>
                                                        <option value="bsnl">BSNL</option>
                                                    </select>
                                                    <div class="invalid-feedback">
                                                        Please select an operator
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <div class="d-grid mt-4">
                                                <button type="submit" class="btn btn-primary btn-lg py-3">
                                                    <i class="fas fa-search me-2"></i> Check Balance
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                    
                                    <% if (SessionUtil.isLoggedIn(session)) { %>
                                    <!-- Auto Recharge Tab (only shown for logged in users) -->
                                    <div class="tab-pane fade" id="auto" role="tabpanel" aria-labelledby="auto-tab">
                                        <form id="autoRechargeForm" method="post" class="needs-validation" novalidate>
                                            <input type="hidden" name="action" value="auto_recharge">
                                            
                                            <div class="row g-3">
                                                <div class="col-md-6">
                                                    <label for="autoMobile" class="form-label">Mobile Number</label>
                                                    <input type="tel" class="form-control" id="autoMobile" name="mobile" 
                                                           pattern="[6-9][0-9]{9}" required 
                                                           placeholder="Enter 10 digit mobile number">
                                                    <div class="invalid-feedback">
                                                        Please enter a valid 10-digit mobile number
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <label for="autoOperator" class="form-label">Operator</label>
                                                    <select class="form-select" id="autoOperator" name="operator" required>
                                                        <option value="" selected disabled>Select Operator</option>
                                                        <option value="airtel">Airtel</option>
                                                        <option value="jio">Jio</option>
                                                        <option value="vi">Vi</option>
                                                        <option value="bsnl">BSNL</option>
                                                    </select>
                                                    <div class="invalid-feedback">
                                                        Please select an operator
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <h5 class="mt-4 mb-3">Select Plan</h5>
                                            <div class="row g-3" id="autoPlansContainer">
                                                <%
                                                try (Connection c = DBUtil.getConnection();
                                                     PreparedStatement stmt = c.prepareStatement(
                                                         "SELECT * FROM recharge_plans ORDER BY amount ASC")) {
                                                    ResultSet rs = stmt.executeQuery();
                                                    
                                                    while (rs.next()) {
                                                        String id = rs.getString("id");
                                                        String desc = rs.getString("description");
                                                        double amount = rs.getDouble("amount");
                                                        String validity = rs.getString("validity");
                                                        String operator = rs.getString("operator");
                                                %>
                                                <div class="col-md-6">
                                                    <div class="card plan-card h-100" onclick="selectAutoPlan(this, '<%= id %>')" 
                                                        role="button" tabindex="0" aria-label="Select <%= desc %> plan">
                                                        <div class="card-body">
                                                            <div class="d-flex justify-content-between align-items-start">
                                                                <div class="plan-price">₹<%= String.format("%.2f", amount) %></div>
                                                                <span class="badge bg-primary"><%= operator %></span>
                                                            </div>
                                                            <h6 class="card-title mt-2"><%= desc %></h6>
                                                            <p class="card-text"><small>Validity: <%= validity %></small></p>
                                                        </div>
                                                    </div>
                                                </div>
                                                <%
                                                    }
                                                } catch (SQLException e) {
                                                    out.println("<div class='col-12'><div class='alert alert-danger'>Error loading plans: " + 
                                                        SecurityUtil.sanitizeInput(e.getMessage()) + "</div></div>");
                                                }
                                                %>
                                            </div>
                                            <input type="hidden" id="autoSelectedPlan" name="plan" required>
                                            
                                            <div class="row g-3 mt-3">
                                                <div class="col-12">
                                                    <label for="frequency" class="form-label">Recharge Frequency</label>
                                                    <select class="form-select" id="frequency" name="frequency" required>
                                                        <option value="" selected disabled>Select Frequency</option>
                                                        <option value="MONTH">Monthly</option>
                                                        <option value="WEEK">Weekly</option>
                                                        <option value="DAY">Daily</option>
                                                    </select>
                                                    <div class="invalid-feedback">
                                                        Please select a frequency
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <div class="d-grid mt-4">
                                                <button type="submit" class="btn btn-primary btn-lg py-3">
                                                    <i class="fas fa-sync-alt me-2"></i> Setup Auto Recharge
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Right Column (Sidebar) -->
                    <div class="col-lg-4">
                        <!-- Quick Recharge Card -->
                        <div class="card mb-4">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0"><i class="fas fa-bolt me-2"></i> Quick Recharge</h5>
                            </div>
                            <div class="card-body">
                                <form id="quickRechargeForm" method="post" class="needs-validation" novalidate>
                                    <input type="hidden" name="action" value="recharge">
                                    
                                    <div class="mb-3">
                                        <label for="quickMobile" class="form-label">Mobile Number</label>
                                        <input type="tel" class="form-control" id="quickMobile" name="mobile" 
                                               pattern="[6-9][0-9]{9}" required 
                                               placeholder="Enter 10 digit mobile number">
                                        <div class="invalid-feedback">
                                            Please enter a valid 10-digit mobile number
                                        </div>
                                    </div>
                                    
                                    <div class="mb-3">
                                        <label for="quickOperator" class="form-label">Operator</label>
                                        <select class="form-select" id="quickOperator" name="operator" required>
                                            <option value="" selected disabled>Select Operator</option>
                                            <option value="airtel">Airtel</option>
                                            <option value="jio">Jio</option>
                                            <option value="vi">Vi</option>
                                            <option value="bsnl">BSNL</option>
                                        </select>
                                        <div class="invalid-feedback">
                                            Please select an operator
                                        </div>
                                    </div>
                                    
                                    <div class="mb-3">
                                        <label for="quickAmount" class="form-label">Amount (₹)</label>
                                        <input type="number" class="form-control" id="quickAmount" name="amount" 
                                               min="10" step="1" required placeholder="Enter amount">
                                        <div class="invalid-feedback">
                                            Please enter an amount (minimum ₹10)
                                        </div>
                                    </div>
                                    
                                    <div class="d-grid">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-bolt me-2"></i> Quick Recharge
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                        
                        <!-- Promotional Offers Card -->
                        <div class="card">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0"><i class="fas fa-tag me-2"></i> Special Offers</h5>
                            </div>
                            <div class="card-body p-0">
                                <div id="offersCarousel" class="carousel slide" data-bs-ride="carousel">
                                    <div class="carousel-inner">
                                        <div class="carousel-item active">
                                            <div class="p-4 text-center">
                                                <div class="bg-light p-4 rounded">
                                                    <h5>Double Data Offer</h5>
                                                    <p class="mb-2">Get double data on selected plans for Airtel and Jio</p>
                                                    <span class="badge bg-success">Valid till 30th</span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="carousel-item">
                                            <div class="p-4 text-center">
                                                <div class="bg-light p-4 rounded">
                                                    <h5>Cashback Offer</h5>
                                                    <p class="mb-2">Get 10% cashback on recharges above ₹299</p>
                                                    <span class="badge bg-success">Valid till 15th</span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="carousel-item">
                                            <div class="p-4 text-center">
                                                <div class="bg-light p-4 rounded">
                                                    <h5>New User Offer</h5>
                                                    <p class="mb-2">First recharge gets extra 10% talktime</p>
                                                    <span class="badge bg-success">Limited time</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <button class="carousel-control-prev" type="button" data-bs-target="#offersCarousel" 
                                        data-bs-slide="prev">
                                        <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                        <span class="visually-hidden">Previous</span>
                                    </button>
                                    <button class="carousel-control-next" type="button" data-bs-target="#offersCarousel" 
                                        data-bs-slide="next">
                                        <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                        <span class="visually-hidden">Next</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        <% } %>
    </div>

    <!-- Footer -->
    <footer class="bg-dark text-white py-4 mt-5 no-print">
        <div class="container">
            <div class="row">
                <div class="col-md-4">
                    <h5><i class="fas fa-mobile-alt me-2"></i> Prepaid Recharge</h5>
                    <p class="text-muted">Fast, secure and easy mobile recharges for all major operators.</p>
                </div>
                <div class="col-md-2">
                    <h5>Quick Links</h5>
                    <ul class="list-unstyled">
                        <li><a href="#" class="text-decoration-none text-muted">Home</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">About Us</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">Contact</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">FAQ</a></li>
                    </ul>
                </div>
                <div class="col-md-3">
                    <h5>Operators</h5>
                    <ul class="list-unstyled">
                        <li><a href="#" class="text-decoration-none text-muted">Airtel</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">Jio</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">Vi</a></li>
                        <li><a href="#" class="text-decoration-none text-muted">BSNL</a></li>
                    </ul>
                </div>
                <div class="col-md-3">
                    <h5>Contact Us</h5>
                    <ul class="list-unstyled text-muted">
                        <li><i class="fas fa-map-marker-alt me-2"></i> 123 Street, City</li>
                        <li><i class="fas fa-phone me-2"></i> +91 9876543210</li>
                        <li><i class="fas fa-envelope me-2"></i> support@prepaidrecharge.com</li>
                    </ul>
                </div>
            </div>
            <hr class="my-4">
            <div class="row">
                <div class="col-md-6">
                    <p class="mb-0">&copy; 2025 Prepaid Recharge. All rights reserved.</p>
                </div>
                <div class="col-md-6 text-md-end">
                    <a href="#" class="text-decoration-none text-muted me-3"><i class="fab fa-facebook-f"></i></a>
                    <a href="#" class="text-decoration-none text-muted me-3"><i class="fab fa-twitter"></i></a>
                    <a href="#" class="text-decoration-none text-muted me-3"><i class="fab fa-instagram"></i></a>
                    <a href="#" class="text-decoration-none text-muted"><i class="fab fa-linkedin-in"></i></a>
                </div>
            </div>
        </div>
    </footer>

    <!-- Login Modal -->
    <div class="modal fade" id="loginModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="post">
                    <input type="hidden" name="action" value="login">
                    <div class="modal-header">
                        <h5 class="modal-title">Login to Your Account</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="loginEmail" class="form-label">Email address</label>
                            <input type="email" class="form-control" id="loginEmail" name="email" required>
                        </div>
                        <div class="mb-3">
                            <label for="loginPassword" class="form-label">Password</label>
                            <input type="password" class="form-control" id="loginPassword" name="password" required>
                        </div>
                        <div class="mb-3 form-check">
                            <input type="checkbox" class="form-check-input" id="rememberMe">
                            <label class="form-check-label" for="rememberMe">Remember me</label>
                        </div>
                        <div class="text-center">
                            <a href="#" class="text-decoration-none">Forgot password?</a>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                        <button type="submit" class="btn btn-primary">Login</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Register Modal -->
    <div class="modal fade" id="registerModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="post">
                    <input type="hidden" name="action" value="register">
                    <div class="modal-header">
                        <h5 class="modal-title">Create New Account</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="registerName" class="form-label">Full Name</label>
                            <input type="text" class="form-control" id="registerName" name="name" required>
                        </div>
                        <div class="mb-3">
                            <label for="registerEmail" class="form-label">Email address</label>
                            <input type="email" class="form-control" id="registerEmail" name="email" required>
                        </div>
                        <div class="mb-3">
                            <label for="registerMobile" class="form-label">Mobile Number</label>
                            <input type="text" class="form-control" id="registerMobile" name="mobile" 
                                   pattern="[0-9]{10}" required placeholder="10 digit mobile number">
                        </div>
                        <div class="mb-3">
                            <label for="registerPassword" class="form-label">Password</label>
                            <input type="password" class="form-control" id="registerPassword" name="password" required>
                        </div>
                        <div class="mb-3">
                            <label for="registerConfirmPassword" class="form-label">Confirm Password</label>
                            <input type="password" class="form-control" id="registerConfirmPassword" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                        <button type="submit" class="btn btn-primary">Register</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- Custom JavaScript -->
    <script>
        // Select plan function
        function selectPlan(element, planId) {
            // Remove selected class from all plans
            document.querySelectorAll('#plansContainer .plan-card').forEach(card => {
                card.classList.remove('selected');
            });
            
            // Add selected class to clicked plan
            element.classList.add('selected');
            
            // Set the selected plan value
            document.getElementById('selectedPlan').value = planId;
        }
        
        // Select auto recharge plan function
        function selectAutoPlan(element, planId) {
            // Remove selected class from all plans
            document.querySelectorAll('#autoPlansContainer .plan-card').forEach(card => {
                card.classList.remove('selected');
            });
            
            // Add selected class to clicked plan
            element.classList.add('selected');
            
            // Set the selected plan value
            document.getElementById('autoSelectedPlan').value = planId;
        }
        
        // Filter plans when operator or circle changes
        document.getElementById('operator').addEventListener('change', function() {
            filterPlans();
        });
        
        document.getElementById('circle').addEventListener('change', function() {
            filterPlans();
        });
        
        function filterPlans() {
            const operator = document.getElementById('operator').value;
            const circle = document.getElementById('circle').value;
            
            if (operator && circle) {
                window.location.href = `prepaid.jsp?operator=${operator}&circle=${circle}`;
            } else if (operator) {
                window.location.href = `prepaid.jsp?operator=${operator}`;
            } else {
                window.location.href = `prepaid.jsp`;
            }
        }
        
        // Password match validation for registration
        document.getElementById('registerConfirmPassword').addEventListener('input', function() {
            const password = document.getElementById('registerPassword').value;
            const confirmPassword = this.value;
            
            if (password !== confirmPassword) {
                this.setCustomValidity("Passwords don't match");
            } else {
                this.setCustomValidity('');
            }
        });
        
        // Show active tab based on URL
        document.addEventListener('DOMContentLoaded', function() {
            const urlParams = new URLSearchParams(window.location.search);
            const action = urlParams.get('action');
            
            if (action === 'balance') {
                const balanceTab = new bootstrap.Tab(document.getElementById('balance-tab'));
                balanceTab.show();
            } else if (action === 'auto') {
                const autoTab = new bootstrap.Tab(document.getElementById('auto-tab'));
                autoTab.show();
            }
            
            // Initialize carousel
            const offersCarousel = new bootstrap.Carousel(document.getElementById('offersCarousel'), {
                interval: 3000,
                ride: 'carousel'
            });
            
            // Add keyboard navigation to plan cards
            document.querySelectorAll('.plan-card').forEach(card => {
                card.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        this.click();
                    }
                });
            });
        });
    </script>
</body>
</html>