<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>
<%
Integer userId = (Integer) session.getAttribute("user_id");
if (userId == null) { response.sendRedirect("../index.jsp"); return; }

int auctionId = Integer.parseInt(request.getParameter("auction_id"));
String bidAmountStr = request.getParameter("bid_amount");
String autoMaxStr = request.getParameter("auto_max"); // optional
double bidAmount = Double.parseDouble(bidAmountStr.trim());
Double autoMax = (autoMaxStr == null || autoMaxStr.trim().isEmpty()) ? null : Double.parseDouble(autoMaxStr.trim());

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    AppDB db = new AppDB();
    con = db.getConnection();
    con.setAutoCommit(false); // important: atomic operations

    // 1) Load auction details
    ps = con.prepareStatement("SELECT start_price, min_price, bid_increment, current_highest_bid, current_highest_bidder, reserve_price, end_time, seller_id FROM auctions WHERE auction_id = ? FOR UPDATE");
    ps.setInt(1, auctionId);
    rs = ps.executeQuery();
    if (!rs.next()) { 
    	session.setAttribute("bidError","Auction not found."); 
    	response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId); return; 
    }

    double startPrice = rs.getDouble("start_price");
    double minPrice = rs.getDouble("min_price"); // reserve is secret but stored
    double increment = rs.getDouble("bid_increment");
    Double currentBid = rs.getObject("current_highest_bid") == null ? null : rs.getDouble("current_highest_bid");
    int currentWinner = rs.getInt("current_highest_bidder");
    Double reserve = rs.getObject("reserve_price") == null ? null : rs.getDouble("reserve_price");
    Timestamp endTime = rs.getTimestamp("end_time");
    int sellerId = rs.getInt("seller_id");

    // check auction active & not ended
    if (endTime != null && endTime.before(new java.util.Date())) {
        session.setAttribute("bidError","Auction already ended.");
        response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId);
        return;
    }

    // Prevent seller bidding on own auction
    if (sellerId == userId) {
        session.setAttribute("bidError","Seller cannot bid on own auction.");
        response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId);
        return;
    }

    // Determine current display price
    double currentDisplay = (currentBid == null) ? startPrice : currentBid;

    // Minimum allowed
    double minAllowed = currentDisplay + increment;
    if (bidAmount < minAllowed) {
        session.setAttribute("bidError","Bid too low. Minimum allowed: " + String.format("%.2f", minAllowed));
        response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId);
        return;
    }

    // 2) Find highest auto_max among existing bidders (excluding retracted/cancelled)
    ps.close();
    rs.close();

    ps = con.prepareStatement(
        "SELECT bidder_id, MAX(auto_max) AS auto_max FROM bids " +
        "WHERE auction_id = ? AND retracted = 0 AND cancelled_by_seller = 0 AND auto_max IS NOT NULL " +
        "GROUP BY bidder_id ORDER BY auto_max DESC"
    );
    ps.setInt(1, auctionId);
    rs = ps.executeQuery();

    // collect top two auto_max entries (if any)
    List<Map<String,Object>> autos = new ArrayList<>();
    while (rs.next()) {
        Map<String,Object> m = new HashMap<>();
        m.put("bidder_id", rs.getInt("bidder_id"));
        m.put("auto_max", rs.getDouble("auto_max"));
        autos.add(m);
    }
    rs.close();
    ps.close();

    Double topAutoMax = null; Integer topAutoBidder = null;
    Double secondAutoMax = null;

    if (autos.size() >= 1) {
        topAutoBidder = (Integer) autos.get(0).get("bidder_id");
        topAutoMax = (Double) autos.get(0).get("auto_max");
    }
    if (autos.size() >= 2) {
        secondAutoMax = (Double) autos.get(1).get("auto_max");
    }

    // 3) Auto-bid logic:
    // If bidder sets autoMax:
    //   - if autoMax > topAutoMax -> bidder becomes highest; display bid = min(autoMax, topAutoMax + increment)
    //   - else -> topAutoBidder remains highest; display bid = min(topAutoMax, autoMax + increment) ??? we will keep previous topAutoMax as display
    //
    // Simpler approach implemented here:
    double newDisplayBid = bidAmount; // what will be set as current_highest_bid
    int newWinner = userId;

    if (autoMax != null) {
        // bidder provided auto_max; consider current top auto
        if (topAutoMax != null && topAutoBidder != null && topAutoBidder != userId) {
            if (autoMax > topAutoMax) {
                // bidder overtakes topAutoBidder; display just above previous top
                newDisplayBid = Math.min(autoMax, topAutoMax + increment);
                newWinner = userId;
            } else {
                // bidder's auto not enough to outbid top; topAuto stays winner
                // topAutoBidder should be displayed at min(topAutoMax, autoMax + increment) or remain topAutoMax? We'll keep topAutoMax as display,
                // but we should create a bid record for the challenger and then create auto counter for topAutoBidder.
                // For simplicity: reject and notify user they were outbid immediately.
                // Insert the user's attempted bid as a record (optional) and notify them. Then rollback logic below.
                // We'll simply notify and redirect.
                session.setAttribute("bidError","Your automatic maximum is too low. Current auto max is " + topAutoMax);
                response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId);
                con.rollback();
                return;
            }
        } else {
            // no existing top auto or top auto belongs to same user -> bidder becomes highest
            newDisplayBid = Math.max(minAllowed, Math.min(autoMax, bidAmount));
            if (newDisplayBid < minAllowed) newDisplayBid = minAllowed;
            newWinner = userId;
        }
    } else {
        // manual bid only (no auto_max)
        if (topAutoMax != null && topAutoBidder != null && topAutoBidder != userId && bidAmount <= topAutoMax) {
            // top auto bidder should automatically counter up to their topAutoMax
            double counterBid = Math.min(topAutoMax, bidAmount + increment);
            // record the manual bid then auto counter - keep counter as current bid
            // insert manual bid (with no auto_max)
            ps = con.prepareStatement("INSERT INTO bids (auction_id, bidder_id, bid_amount, auto_max) VALUES (?, ?, ?, NULL)");
            ps.setInt(1, auctionId);
            ps.setInt(2, userId);
            ps.setDouble(3, bidAmount);
            ps.executeUpdate();
            ps.close();

            // insert auto counter for topAutoBidder
            ps = con.prepareStatement("INSERT INTO bids (auction_id, bidder_id, bid_amount, auto_max) VALUES (?, ?, ?, ?)");
            ps.setInt(1, auctionId);
            ps.setInt(2, topAutoBidder);
            ps.setDouble(3, counterBid);
            ps.setDouble(4, topAutoMax);
            ps.executeUpdate();
            ps.close();

            // update auctions table with counterBid
            ps = con.prepareStatement("UPDATE auctions SET current_highest_bid=?, current_highest_bidder=? WHERE auction_id=?");
            ps.setDouble(1, counterBid);
            ps.setInt(2, topAutoBidder);
            ps.setInt(3, auctionId);
            ps.executeUpdate();
            ps.close();

            // notify both parties
            ps = con.prepareStatement("INSERT INTO notifications (user_id, auction_id, message) VALUES (?, ?, ?)");
            ps.setInt(1, userId);
            ps.setInt(2, auctionId);
            ps.setString(3, "Your bid was immediately outbid by an automatic bidder.");
            ps.executeUpdate();
            ps.setInt(1, topAutoBidder);
            ps.setString(3, "Your automatic bid increased to $" + counterBid);
            ps.executeUpdate();
            ps.close();

            con.commit();
            response.sendRedirect("../viewAuction.jsp?auction_id="+auctionId);
            return;
        } else {
            // no auto competitor -> manual bid becomes current
            newDisplayBid = Math.max(bidAmount, minAllowed);
            newWinner = userId;
        }
    }

    // 4) Persist the winning insert (either new auto bid or manual)
    ps = con.prepareStatement("INSERT INTO bids (auction_id, bidder_id, bid_amount, auto_max) VALUES (?, ?, ?, ?)");
    ps.setInt(1, auctionId);
    ps.setInt(2, newWinner);
    ps.setDouble(3, newDisplayBid);
    if (autoMax != null) ps.setDouble(4, autoMax); else ps.setNull(4, java.sql.Types.DOUBLE);
    ps.executeUpdate();
    ps.close();

    // 5) Update auctions current_highest_bid and bidder
    ps = con.prepareStatement("UPDATE auctions SET current_highest_bid=?, current_highest_bidder=? WHERE auction_id=?");
    ps.setDouble(1, newDisplayBid);
    ps.setInt(2, newWinner);
    ps.setInt(3, auctionId);
    ps.executeUpdate();
    ps.close();

    // 6) Notify previous highest bidder that they've been outbid
    if (currentBid != null && currentBid > 0 && currentWinner != userId) {
        ps = con.prepareStatement("INSERT INTO notifications (user_id, auction_id, message) VALUES (?, ?, ?)");
        ps.setInt(1, currentWinner);
        ps.setInt(2, auctionId);
        ps.setString(3, "You have been outbid on auction #" + auctionId + ". Current bid: $" + newDisplayBid);
        ps.executeUpdate();
        ps.close();
    }

    con.commit();
    response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
    return;
} catch (Exception e) {
    if (con != null) try { con.rollback(); } catch (Exception ex) {}
    session.setAttribute("bidError", "Error placing bid: " + e.getMessage());
    response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
    return;
} finally {
    try { if (rs != null) rs.close(); } catch (Exception ex) {}
    try { if (ps != null) ps.close(); } catch (Exception ex) {}
    try { if (con != null) con.setAutoCommit(true); con.close(); } catch (Exception ex) {}
	}%>
