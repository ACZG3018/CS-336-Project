<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Welcome!</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: lightgray;
            flex-direction: column;
        }
        .welcome-container {
            background-color: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            text-align: center;
        }
        .logout-button {            
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 4px;
            background-color: red;
            color: white;
            font-size: 1rem;
            cursor: pointer;
            text-decoration: none;
        }
        
    </style>
</head>
<body>
    <div class="welcome-container">
        <h2>Access Granted!</h2>
        <p>You have successfully logged in.</p>
        
        <form action="index.jsp" method="GET">
            <button type="submit" class="logout-button">Log Out</button>
        </form>
    </div>
</body>
</html>