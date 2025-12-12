<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    String auctionIdStr = request.getParameter("auction_id");
    String cardNumber = request.getParameter("card_number");

    if (userId != null && auctionIdStr != null && cardNumber != null) {
        // Simple "Fake" Validation: Check if it's 16 digits
        if (cardNumber.matches("\\d{16}")) {
            AppDB db = new AppDB();
            Connection con = db.getConnection();

            // 1. Mark auction as CLOSED (removes from listings if your listing query checks status)
            String updateSql = "UPDATE auctions SET status = 'closed' WHERE auction_id = ? AND current_highest_bidder = ?";
            PreparedStatement ps = con.prepareStatement(updateSql);
            ps.setInt(1, Integer.parseInt(auctionIdStr));
            ps.setInt(2, userId);
            ps.executeUpdate();
            
            ps.close();
            con.close();
            
            // Redirect to a success page or back to home
            response.sendRedirect("../index.jsp?msg=PaymentSuccess");
        } else {
            response.sendRedirect("../index.jsp?error=InvalidCard");
        }
    } else {
        response.sendRedirect("../index.jsp?error=Error");
    }
%>