<%@page import="java.time.LocalTime, java.time.format.DateTimeFormatter"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>

<%
    AppDB db = new AppDB();
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

	// Remove Auctions
    String removeAuctionID = request.getParameter("removeAuction");
    if (removeAuctionID != null) {
    	con = db.getConnection();
        ps = con.prepareStatement("DELETE FROM auctions WHERE auction_id = ?");
        ps.setInt(1, Integer.parseInt(removeAuctionID));
        ps.executeUpdate();
    }

    // Remove Bids
    String removeBidAuctionID = request.getParameter("removeBidAuction");
    String removeBidder = request.getParameter("removeBidder");
    
    if (removeBidAuctionID != null && removeBidder != null) {
    	con = db.getConnection();
        ps = con.prepareStatement("DELETE FROM bids WHERE auction_id = ? AND bidder_id = ?");
        ps.setInt(1, Integer.parseInt(removeBidAuctionID));
        ps.setInt(2, Integer.parseInt(removeBidder));
        ps.executeUpdate();
        ps.close();
        
        int auctionId = Integer.parseInt(removeBidAuctionID);
        ps = con.prepareStatement("SELECT MAX(bid_amount) AS max_bid FROM bids WHERE auction_id = ?");
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();
        
        Double newHighBid = null;
        if (rs.next()) {
            newHighBid = rs.getObject("max_bid") == null ? null : rs.getDouble("max_bid");
        }
        rs.close();
        ps.close();

        if (newHighBid == null) {
            ps = con.prepareStatement("SELECT start_price FROM auctions WHERE auction_id = ?");
            ps.setInt(1, auctionId);
            rs = ps.executeQuery();
            if (rs.next()) { newHighBid = rs.getDouble("start_price"); }
            rs.close();
            ps.close();
        }

        ps = con.prepareStatement("UPDATE auctions SET current_highest_bid = ? WHERE auction_id = ?");
        ps.setDouble(1, newHighBid);
        ps.setInt(2, auctionId);
        ps.executeUpdate();
        ps.close();
    }

    // Reply To Users
    String replyTicket = request.getParameter("replyTicket");
	String replyText = request.getParameter("replyText");
	if (replyTicket != null && replyText != null) {
		con = db.getConnection();
        ps = con.prepareStatement("INSERT INTO answers (question_id, user_id, content) VALUES (?, ?, ?)");
        
        ps.setInt(1, Integer.parseInt(replyTicket));
        ps.setInt(2, (int)session.getAttribute("user_id"));
        ps.setString(3, replyText);
        ps.executeUpdate();
        ps.close();
	
	    response.sendRedirect(request.getRequestURI());
	}

    // Admin Chat
	String adminChatText = request.getParameter("adminChatText");
	
	if (adminChatText != null) {
	    String adminChatSender = (String) session.getAttribute("username");
	    
	    con = db.getConnection();
        ps = con.prepareStatement("INSERT INTO admin_messages (sender, message) VALUES (?, ?)");
       
        ps.setString(1, adminChatSender);
        ps.setString(2, adminChatText);
        ps.executeUpdate();
        ps.close();

	    response.sendRedirect(request.getRequestURI());
	}

%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
    <title>Customer Representative Helpdesk</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; padding: 20px; }
        .card { box-shadow: 0 3px 5px rgba(0,0,0,0.1); }
        .card-header { font-weight: bold; background-color: #198754; color: white; }
        .chat-box { height: 300px; overflow-y: scroll; background: #f1f1f1; padding: 10px; }
        .chat-msg { margin-bottom: 12px; }
    </style>
</head>

<body>
	<div class="container">
		<h1 class="mb-4 text-center">Customer Representative Helpdesk</h1>
		<div class="row">
			<!-- Auctions  -->
		    <div class="col-md-4">
		        <div class="card h-100">
		            <div class="card-header bg-primary">Active Auctions</div>
		            <div class="card-body">
		                <table class="table table-sm table-hover">
		                    <thead>
		                        <tr>
		                        	<th>ID</th>
		                        	<th>Vehicle</th>
		                        	<th>Seller</th>
		                        </tr>
		                    </thead>
		                    <tbody>
		                    <%
		                        con = db.getConnection();
		                        ps = con.prepareStatement(
		                            "SELECT a.auction_id, v.make, v.model, u.user_name " +
		                            "FROM auctions a " +
		                            "JOIN vehicles v ON a.vehicle_id=v.vehicle_id " +
		                            "JOIN users u ON u.user_id=a.seller_id"
		                        );
		                        rs = ps.executeQuery();
		                        while (rs.next()) {
		                            int aid = rs.getInt("auction_id");
		                            String make = rs.getString("make") + " " + rs.getString("model");
		                            String seller = rs.getString("user_name");
		                    %>
		                    
		                        <tr>
		                            <td><%=aid%></td>
		                            <td><%=make%></td>
		                            <td><%=seller%></td>
		                            <td>
		                                <button class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#auctionModal_<%=aid%>">View</button>
		                            </td>
		                        </tr>
		                        
		                    <% } 
		                        rs.close(); 
		                    	ps.close(); 
		                    	con.close(); 
		                   %>
		                    </tbody>
		                </table>
		            </div>
		        </div>
		    </div>
		
		    <!-- Question Support Tickets  -->
			<div class="col-md-4">
			    <div class="card h-100">
			        <div class="card-header bg-warning">Question Support</div>
			        <div class="card-body">
			            <h6>Question List</h6>
			            <ul class="list-group mb-3">
			                <%
			                    con = db.getConnection();
			                    ps = con.prepareStatement(
			                        "SELECT q.question_id, q.content, u.user_name " +
			                        "FROM questions q " +
			                        "JOIN users u ON q.user_id = u.user_id " +
			                        "ORDER BY q.question_id DESC"
			                    );
			                    rs = ps.executeQuery();
			                    while(rs.next()) {
			                        int questionId = rs.getInt("question_id");
			                        String questionContent = rs.getString("content");
			                        String questionUser = rs.getString("user_name");
			                %>
			                <li class="list-group-item d-flex justify-content-between align-items-center">
							    <strong>Question <%=questionId%>:</strong> 
							    <%=questionContent.length() > 40 ? questionContent.substring(0, 40) + "..." : questionContent %> 
							    <br><small class="text-muted">From: <%=questionUser%></small>
							    <button class="btn btn-sm btn-outline-secondary" data-bs-toggle="modal" data-bs-target="#questionModal_<%=questionId%>">Open</button>
							</li>
			                <% } rs.close(); ps.close(); con.close(); %>
			            </ul>
			        </div>
			    </div>
			</div>
		
			<!-- Admin Contact  -->
			<div class="col-md-4">
			    <div class="card h-100">
			        <div class="card-header bg-info text-white">Admin Chat</div>
			        <div class="card-body">
			            <div class="chat-box mb-3">
			                <%
			                    con = db.getConnection();
			                    ps = con.prepareStatement("SELECT sender, message, sent_time FROM admin_messages ORDER BY sent_time");
			                    rs = ps.executeQuery();
			                    while (rs.next()) {
			                        String sender = rs.getString("sender");
			                        String message = rs.getString("message");
			                        Timestamp time = rs.getTimestamp("sent_time");
			                %>
			                
			                <div class="chat-msg">
			                    <strong><%=sender%>:</strong><br>
			                    <%=message%><br>
			                    <small class="text-muted"><%=time%></small>
			                </div>
			                
			                <% } 
			            		rs.close(); 
			            		ps.close(); 
			            		con.close(); 
			            	%>
			            </div>
			            <form method="post">
			                <textarea class="form-control mb-2" name="adminChatText" placeholder="Message..." required></textarea>
			                <button class="btn btn-primary w-100">Send</button>
			            </form>
			        </div>
			    </div>
			</div>
		</div>
		
		<%
		    con = db.getConnection();
		    ps = con.prepareStatement(
		        "SELECT a.auction_id, v.make, v.model, u.user_name, a.current_highest_bid " +
		        "FROM auctions a " +
		        "JOIN vehicles v ON a.vehicle_id=v.vehicle_id " +
		        "JOIN users u ON a.seller_id=u.user_id"
		    );
		    rs = ps.executeQuery();
		    
		    while (rs.next()) {
		        int aid = rs.getInt("auction_id");
		        String title = rs.getString("make") + " " + rs.getString("model");
		        String seller = rs.getString("user_name");
		        Double chb = rs.getDouble("current_highest_bid");
		%>
		
		<div class="modal fade" id="auctionModal_<%=aid%>" tabindex="-1">
		    <div class="modal-dialog modal-dialog-scrollable modal-xl">
		        <div class="modal-content">
		            <div class="modal-header bg-primary text-white">
		                <h5 class="modal-title">Auction: <%=title%> (ID: <%=aid%>)</h5>
		                <button class="btn-close" data-bs-dismiss="modal"></button>
		            </div>
		            <div class="modal-body">
		                <p>
		                	<strong>Seller:</strong> 
		                	<%=seller%>
		                </p>
		                <p><strong>Current Price:</strong>
		                    <span class="text-success fw-bold">
		                        <%= ("$" + chb) %>
		                    </span>
		                </p>
		                <hr>
		                <h6 class="mb-2 text-muted">Bid History</h6>
		                <table class="table table-striped">
		                    <thead class="table-dark">
		                        <tr>
		                        	<th>User</th>
		                        	<th>Amount</th>
		                        	<th>Time</th>
		                        	<th></th>
		                        </tr>
		                    </thead>
		                    <tbody>
		                    <%
		                        PreparedStatement ps2 = con.prepareStatement(
		                            "SELECT b.bidder_id, u.user_name, b.bid_amount, b.bid_time " +
		                            "FROM bids b " +
		                            "JOIN users u ON b.bidder_id=u.user_id " +
		                            "WHERE b.auction_id = ? ORDER BY b.bid_time DESC"
		                        );
		                        ps2.setInt(1, aid);
		                        ResultSet rs2 = ps2.executeQuery();
		                        while (rs2.next()) {
		                    %>
		                        <tr>
		                            <td><%=rs2.getString("user_name")%></td>
		                            <td class="text-success fw-bold">$<%=rs2.getDouble("bid_amount")%></td>
		                            <td><%=rs2.getTimestamp("bid_time")%></td>
		                            <td>
		                                <form method="get">
		                                    <input type="hidden" name="removeBidAuction" value="<%=aid%>">
		                                    <input type="hidden" name="removeBidder" value="<%=rs2.getInt("bidder_id")%>">
		                                    <button class="btn btn-sm btn-danger">Remove Bid</button>
		                                </form>
		                            </td>
		                        </tr>
		                    <% } 
		                    	rs2.close(); 
		                    	ps2.close(); 
		                    %>
		                    </tbody>
		                </table>
		            </div>
		            <div class="modal-footer">
		                <form method="get">
		                    <input type="hidden" name="removeAuction" value="<%=aid%>">
		                    <button class="btn btn-danger">Remove Auction</button>
		                </form>
		                <button class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
		            </div>
		        </div>
		    </div>
		</div>
		<% } 
		    rs.close(); 
		    ps.close(); 
		    con.close(); 
		%>
		
		<%
		    con = db.getConnection();
		    ps = con.prepareStatement(
		        "SELECT q.question_id, q.content, u.user_name " +
		        "FROM questions q " + 
		       	"JOIN users u ON q.user_id = u.user_id"
		    );
		    rs = ps.executeQuery();
		    while(rs.next()) {
		        int questionId = rs.getInt("question_id");
		        String questionContent = rs.getString("content");
		        String questionUser = rs.getString("user_name");
		%>
		<div class="modal fade" id="questionModal_<%=questionId%>" tabindex="-1">
		    <div class="modal-dialog modal-dialog-scrollable modal-xl">
		        <div class="modal-content">
		            <div class="modal-header bg-warning text-dark">
		                <h5 class="modal-title">Question<%=questionId%> — <%=questionContent%></h5>
						<small class="text-muted" style="display:block; margin-left: 20px;">Submitted by: <%=questionUser%></small>
		                <button class="btn-close" data-bs-dismiss="modal"></button>
		            </div>
		            <div class="modal-body">
		                <div class="chat-box mb-3">
		                    <%
		                        PreparedStatement ps2 = con.prepareStatement(
		                            "SELECT a.content AS message, u.user_name AS sender, u.role AS sender_role, a.created_at AS sent_time " +
		                            "FROM answers a " + 
		                            "JOIN users u ON a.user_id = u.user_id " +
		                            "WHERE a.question_id = ? ORDER BY a.created_at"
		                        );
		                        ps2.setInt(1, questionId);
		                        ResultSet rs2 = ps2.executeQuery();
		                        while(rs2.next()) {
		                            String sender = rs2.getString("sender");
		                            String senderRole = rs2.getString("sender_role");
		                            String message = rs2.getString("message");
		                            Timestamp sentTime = rs2.getTimestamp("sent_time");
		                    %>
		                    <div class="chat-msg">
		                        <strong><%=sender%> (<%=senderRole%>)</strong>: <%=message%><br>
		                        <small class="text-muted"><%=sentTime%></small>
		                    </div>
		                    <% } rs2.close(); ps2.close(); %>
		                </div>
		                <form method="get">
		                    <input type="hidden" name="replyTicket" value="<%=questionId%>">
		                    <textarea class="form-control mb-2" name="replyText" placeholder="Reply..." required></textarea>
		                    <button class="btn btn-success w-100">Send</button>
		                </form>
		            </div>
		        </div>
		    </div>
		</div>
		<% } 
		    rs.close(); 
		    ps.close(); 
		    con.close(); 
		%>
		
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</div>
</body>
</html>
