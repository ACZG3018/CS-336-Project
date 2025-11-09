<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>


<!DOCTYPE html>

<html>
	<head>
	    <meta charset="UTF-8">
	    <title> CS 336 Project - Login Page </title>
	    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: gray;
        }
        .login-container {
            background-color: white;
            padding: 1rem;
            width: 300px;
        }
        .login-container h2 {
            text-align: center;
            margin-bottom: 1.5rem;
        }
        .form-group {
            margin-bottom: 1rem;
        }
        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
        }
        .form-group input {
            width: 100%;
            padding: 0.5rem;
            box-sizing: border-box;
            border: 1px solid #ddd;
           
        }
        .login-button {
            width: 100%;
            padding: 0.75rem;
            border: none;
            border-radius: 4px;
            background-color: blue;
            color: white;
            font-size: 1rem;
            cursor: pointer;
        }
    </style>
	</head>
	
	<body>
		<%
	    String errorMessage = null;
	
	    if ("POST".equals(request.getMethod())) {
	        
	        String user = request.getParameter("username");
	        String pass = request.getParameter("password");	   
	        Connection con = null;
	        PreparedStatement ps = null;
	        ResultSet rs = null;
	
	        try {
	        	AppDB db = new AppDB();	
				con = db.getConnection();
	            
	            String sql = "SELECT * FROM Users WHERE username = ? AND password = ?";
	            ps = con.prepareStatement(sql);
	            ps.setString(1, user);
	            ps.setString(2, pass);
	            rs = ps.executeQuery();
	
	            if (rs.next()) {
	                response.sendRedirect("Access Granted");
	                return;
	            } else {	               
	                errorMessage = "Access Denied. Please try again.";
	            }
	
	        } catch (Exception e) {
	            e.printStackTrace();
	            errorMessage = "An error occurred. Please try again.";
	        } finally {
	            // 5. Always close resources
	            try { if (rs != null) rs.close(); } catch (Exception e) {};
	            try { if (ps != null) ps.close(); } catch (Exception e) {};
	            try { if (con != null) con.close(); } catch (Exception e) {};
	        }
	    }
		%>
	    <div class="login-container">
	        <h2>Log In Test</h2>
	        
	        <%-- 6. This HTML-embedded code displays the error --%>
        <%if (errorMessage != null) {
            	out.println(errorMessage);
            }%>
            	        
	        <form action="index.jsp" method="POST">
	            <div class="form-group">
	                <label for="username">Username:</label>
	                <input type="text" id="username" name="username" required>
	            </div>
	            
	            <div class="form-group">
	                <label for="password">Password:</label>
	                <input type="password" id="password" name="password" required>
	            </div>
	            
	            <button type="submit" class="login-button">Login</button>
	        </form>
	    </div>

	</body>
	
</html>