<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
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
            background-color: lightgray;
        }
        .login-container {
            background-color: white;
            padding: 1rem;
            width: 300px;
        }
        .login-container h2 {
            text-align: center;
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
	        String passwd = request.getParameter("password");	   
	        Connection con = null;
	        PreparedStatement ps = null;
	        ResultSet rs = null;
	
	        try {
	        	AppDB db = new AppDB();	
				con = db.getConnection();

	            ps = con.prepareStatement("SELECT * FROM Users WHERE user_name = ? AND password = ?");
	            ps.setString(1, user);
	            ps.setString(2, passwd);
	            rs = ps.executeQuery();
	
	            if (rs.next()) {
	            	session.setAttribute("user_id", rs.getInt("user_id"));
	                session.setAttribute("username", rs.getString("user_name"));
	                response.sendRedirect("auctions.jsp");
	                return;
	           
	            } else {	               
	            	session.setAttribute("errorMessage", "Access Denied. Please try again.");
	                response.sendRedirect("index.jsp");
	                return;
	            }
	
	        } catch (Exception e) {
	            e.printStackTrace();
	            session.setAttribute("errorMessage", "An error occurred.");
	            response.sendRedirect("index.jsp");
	            return;
	        } finally {
	            try { if (rs != null) rs.close(); } catch (Exception e) {};
	            try { if (ps != null) ps.close(); } catch (Exception e) {};
	            try { if (con != null) con.close(); } catch (Exception e) {};
	        }
	    }
		%>
		
	    <div class="login-container">
	   <h2>Log In</h2>
	        
        <% 
        String errorMessageString = (String) session.getAttribute("errorMessage");
        if (errorMessageString != null) {
            	out.println(errorMessageString);
            	session.removeAttribute("errorMessage");
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
	        
    		<form action="createAccount.jsp">
        		<button class="create-button">Create Account</button>
    		</form>
    		
    		<form action="admin_dashboard.jsp">
        		<button class="admin-link">Administration</button>
    		</form>    		
	    </div>
	</body>
</html>