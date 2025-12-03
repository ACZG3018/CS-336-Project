<%@ page import="java.sql.*,com.cs336_project.pkg.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>Create Account</title>
    <style>
        body {
            display: flex; justify-content: center; align-items: center;
            height: 100vh; background-color: lightgray;
        }
        .container {
            background: white; padding: 1rem; width: 350px;
        }
        .form-group { margin-bottom: 1rem; }
        .form-group label { display: block; margin-bottom: 0.3rem; }
        .form-group input { width: 100%; padding: 0.5rem; }
        button {
            width: 100%; padding: 0.75rem; border: none; border-radius: 4px;
            background-color: green; color: white; cursor: pointer; font-size: 1rem;
        }
    </style>
</head>
<body>

<%
if ("POST".equals(request.getMethod())) {

    String username = request.getParameter("username");
    String fullname = request.getParameter("fullname");
    String email = request.getParameter("email");
    String address = request.getParameter("address");
    String phone = request.getParameter("phone");
    String password = request.getParameter("password");

    Connection con = null;
    PreparedStatement ps = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        ps = con.prepareStatement(
            "INSERT INTO users (user_name, full_name, email, address, phone, password) VALUES (?, ?, ?, ?, ?, ?)"
        );

        ps.setString(1, username);
        ps.setString(2, fullname);
        ps.setString(3, email);
        ps.setString(4, address);
        ps.setString(5, phone);
        ps.setString(6, password);

        ps.executeUpdate();

        session.setAttribute("success", "Account created! Please log in.");
        response.sendRedirect("index.jsp");
        return;

    } catch (SQLIntegrityConstraintViolationException e) {
        out.println("<p style='color:red'>Username already exists.</p>");
    } catch (Exception e) {
        e.printStackTrace();
        out.println("<p style='color:red'>Error creating account.</p>");
    } finally {
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (con != null) con.close(); } catch (Exception e) {}
    }
}
%>

<div class="container">
    <h2>Create Account</h2>

    <form method="POST" action="createAccount.jsp">
        <div class="form-group">
            <label>Username</label>
            <input type="text" name="username" required maxlength="30">
        </div>

        <div class="form-group">
            <label>Full Name</label>
            <input type="text" name="fullname" maxlength="50">
        </div>

        <div class="form-group">
            <label>Email</label>
            <input type="email" name="email" maxlength="50">
        </div>

        <div class="form-group">
            <label>Address</label>
            <input type="text" name="address" maxlength="100">
        </div>

        <div class="form-group">
            <label>Phone</label>
            <input type="text" name="phone" maxlength="20">
        </div>

        <div class="form-group">
            <label>Password</label>
            <input type="password" name="password" required maxlength="25">
        </div>

        <button type="submit">Create Account</button>
    </form>
</div>

</body>
</html>