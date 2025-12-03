package com.cs336_project.pkg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class AppDB {
	
	public AppDB(){
		
	}
	public Connection getConnection(){
		// String connectionUrl = "jdbc:mysql://localhost:3306/cs_336_project_3?useSSL=false&serverTimezone=UTC";
	    // Connection connection = null;
		String connectionUrl = "jdbc:mysql://localhost:3306/cs_336_project_3";
		Connection connection = null;
		
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			System.out.println("Driver loaded");
		} catch (Exception e) {
	        System.out.println("Driver NOT loaded");
	        e.printStackTrace();
	    }
		try {
			connection = DriverManager.getConnection(connectionUrl,"root", "password");
			System.out.println("Connected successfully!");
		} catch (SQLException e) {
			System.out.println("Connection FAILED!");
			e.printStackTrace();
		}
		
		return connection;
		
	}
	
	public void closeConnection(Connection connection){
		try {
			connection.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	
	public static void main(String[] args) {
		AppDB dao = new AppDB();
		Connection connection = dao.getConnection();
		
		System.out.println(connection);		
		dao.closeConnection(connection);
	}
	
	

}


