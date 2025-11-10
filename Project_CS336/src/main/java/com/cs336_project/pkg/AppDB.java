package com.cs336_project.pkg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class AppDB {
	
	public AppDB(){
		
	}
	
	public Connection getConnection(){
		
		String connectionUrl = "jdbc:mysql://localhost:3306/cs336_project";
		Connection connection = null;
		
		try {
			Class.forName("com.mysql.cj.jdbc.Driver").newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
		try {
			connection = DriverManager.getConnection(connectionUrl,"root", "password");
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		return connection;
		
	}
	
	public void closeConnection(Connection connection){
		try {
			connection.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
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


