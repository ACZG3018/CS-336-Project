<%@page import="java.time.LocalTime, java.time.format.DateTimeFormatter"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>

<%
    LocalTime now = LocalTime.now();
	DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm");
	
    // 1. Mock Bids
    List<String[]> activeBids = new ArrayList<>();
    activeBids.add(new String[]{"Mazda CX-30", "user_1", "$2500", now.format(formatter).toString()});
    activeBids.add(new String[]{"Toyota Corolla", "user_2", "$8500", now.format(formatter).toString()});
    activeBids.add(new String[]{"Honda CR-V", "user_2", "$45000", now.format(formatter).toString()});

    // 2. Mock Accounts
    List<String[]> csAccounts = new ArrayList<>();
    csAccounts.add(new String[]{"Emp001", "Sarah Smith", "Support"});
    csAccounts.add(new String[]{"Emp002", "John Doe", "Support"});

    List<String[]> allUsers = new ArrayList<>();
    allUsers.add(new String[]{"user_1", "Alice W.", "Active"});
    allUsers.add(new String[]{"user_2", "Bob J.", "Inactive"});

    // 3. Logic for Report Generation (Simulating a form submission)
    String reportType = request.getParameter("reportType");
    String reportResult = "";
    if(reportType == null) reportType = "none";
%>

<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Admin Server</title>
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; padding: 20px;}
        .card { box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .card-header { font-weight: bold; background-color: #0d6efd; color: white; }
    </style>
</head>

<body>
<div class="container">
    <h1 class="mb-4 text-center">Admin Control Panel</h1>

    <div class="row mb-4">
        <div class="col-12">
            <div class="card">
                <div class="card-body d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title">Live Auction Activity</h5>
                        <p class="card-text">Monitor incoming bids in real-time.</p>
                    </div>
                    <button type="button" class="btn btn-primary btn-lg" data-bs-toggle="modal" data-bs-target="#bidsModal">
                        Open Current Bids Window
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">User Management</div>
                <div class="card-body">
                    <ul class="nav nav-tabs" id="userTabs" role="tablist">
                        <li class="nav-item" role="presentation">
                            <button class="nav-link active" id="cs-tab" data-bs-toggle="tab" data-bs-target="#cs" type="button" role="tab">CS Accounts</button>
                        </li>
                        <li class="nav-item" role="presentation">
                            <button class="nav-link" id="status-tab" data-bs-toggle="tab" data-bs-target="#status" type="button" role="tab">Account Status</button>
                        </li>
                    </ul>

                    <div class="tab-content mt-3" id="userTabsContent">
                        
                        <div class="tab-pane fade show active" id="cs" role="tabpanel">
                            <h6 class="text-muted">Staff Directory</h6>
                            <table class="table table-sm table-hover">
                                <thead><tr><th>ID</th><th>Name</th><th>Role</th></tr></thead>
                                <tbody>
                                    <% for(String[] emp : csAccounts) { %>
                                    <tr>
                                        <td><%= emp[0] %></td>
                                        <td><%= emp[1] %></td>
                                        <td><span class="badge bg-info text-dark"><%= emp[2] %></span></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>

                        <div class="tab-pane fade" id="status" role="tabpanel">
                            <h6 class="text-muted">User Activity Log</h6>
                            <table class="table table-sm">
                                <thead><tr><th>Username</th><th>Name</th><th>Status</th></tr></thead>
                                <tbody>
                                    <% for(String[] usr : allUsers) { %>
                                    <tr>
                                        <td><%= usr[0] %></td>
                                        <td><%= usr[1] %></td>
                                        <td>
                                            <% if(usr[2].equals("Active")) { %>
                                                <span class="badge bg-success">Active</span>
                                            <% } else { %>
                                                <span class="badge bg-danger">Inactive</span>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header bg-success">Sales & Analytics</div>
                <div class="card-body">
                    <form action="admin_dashboard.jsp" method="get" class="mb-4">
                        <div class="mb-3">
                            <label for="reportType" class="form-label">Select Report Type:</label>
                            <select class="form-select" name="reportType" id="reportType">
                                <option value="total" <%= "total".equals(reportType) ? "selected" : "" %>>Total Earnings</option>
                                <option value="perItem" <%= "perItem".equals(reportType) ? "selected" : "" %>>Earnings per Item Type</option>
                                <option value="bestSeller" <%= "bestSeller".equals(reportType) ? "selected" : "" %>>Bestselling End-Users</option>
                            </select>
                        </div>
                        <button type="submit" class="btn btn-success w-100">Generate Report</button>
                    </form>

                    <div class="border rounded p-3 bg-light">
                        <h6 class="border-bottom pb-2">Report Results</h6>
                        <% 
                        if(reportType.equals("total")) { 
                        %>
                            <h3 class="text-success">$14,250.00</h3>
                            <small>Total platform earnings (Lifetime)</small>
                        <% 
                        } else if(reportType.equals("perItem")) { 
                        %>
                            <ul class="list-group">
                                <li class="list-group-item d-flex justify-content-between align-items-center">
                                    Trucks
                                    <span class="badge bg-primary rounded-pill">$5,000</span>
                                </li>
                                <li class="list-group-item d-flex justify-content-between align-items-center">
                                    Cars
                                    <span class="badge bg-primary rounded-pill">$2,100</span>
                                </li>
                            </ul>
                        <% 
                        } else if(reportType.equals("bestSeller")) { 
                        %>
                            <ol>
                                <li><strong>Seller_X</strong> (50 items sold)</li>
                                <li><strong>ShopMaster</strong> (32 items sold)</li>
                            </ol>
                        <% 
                        } else { 
                        %>
                            <p class="text-muted">Please select a report type and click generate.</p>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="bidsModal" tabindex="-1" aria-labelledby="bidsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="bidsModalLabel">Current Live Bids</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <table class="table table-striped">
                    <thead class="table-dark">
                        <tr>
                            <th>Item</th>
                            <th>Bidder</th>
                            <th>Amount</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for(String[] bid : activeBids) { %>
                        <tr>
                            <td><%= bid[0] %></td>
                            <td><%= bid[1] %></td>
                            <td class="text-success fw-bold"><%= bid[2] %></td>
                            <td><%= bid[3] %></td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>