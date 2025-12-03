<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>

<%
    request.setCharacterEncoding("UTF-8");

    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Read form fields
    String make = request.getParameter("make");
    String model = request.getParameter("model");
    String yearStr = request.getParameter("year");
    String type = request.getParameter("type");

    String bodyStyle = request.getParameter("body_style");
    String numDoorsStr = request.getParameter("num_doors");

    String numWheelsStr = request.getParameter("num_wheels");
    String axleConfig = request.getParameter("axle_config");

    String hasSidecarStr = request.getParameter("has_sidecar");
    String handlebarStyle = request.getParameter("handlebar_style");

    String startPriceStr = request.getParameter("start_price");
    String minPriceStr = request.getParameter("min_price");
    String bidIncrementStr = request.getParameter("bid_increment");
    String reservePriceStr = request.getParameter("reserve_price");
    String endTimeStr = request.getParameter("end_time");

    // Basic validation
    if (make == null || model == null || yearStr == null || type == null ||
        startPriceStr == null || minPriceStr == null || bidIncrementStr == null ||
        endTimeStr == null || make.trim().equals("") || model.trim().equals("")) {

        session.setAttribute("createError", "Missing required fields.");
        response.sendRedirect("createListing.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        // 1. Insert into vehicles
        String insertVehicle =
            "INSERT INTO vehicles (make, model, year, type) VALUES (?, ?, ?, ?)";

        ps = con.prepareStatement(insertVehicle, Statement.RETURN_GENERATED_KEYS);
        ps.setString(1, make);
        ps.setString(2, model);
        ps.setInt(3, Integer.parseInt(yearStr));
        ps.setString(4, type);
        ps.executeUpdate();

        rs = ps.getGeneratedKeys();
        if (!rs.next()) {
            session.setAttribute("createError", "Failed to create vehicle.");
            response.sendRedirect("createListing.jsp");
            return;
        }
        int vehicleId = rs.getInt(1);

        rs.close();
        ps.close();

        // 2. Insert into subtype tables
        if (type.equalsIgnoreCase("car")) {
            String sql = "INSERT INTO cars (vehicle_id, body_style, num_doors) VALUES (?, ?, ?)";
            ps = con.prepareStatement(sql);
            ps.setInt(1, vehicleId);
            ps.setString(2, bodyStyle);
            ps.setInt(3, (numDoorsStr == null || numDoorsStr.equals("")) ? 0 : Integer.parseInt(numDoorsStr));
            ps.executeUpdate();
            ps.close();
        }
        else if (type.equalsIgnoreCase("truck")) {
            String sql = "INSERT INTO trucks (vehicle_id, num_wheels, axle_config) VALUES (?, ?, ?)";
            ps = con.prepareStatement(sql);
            ps.setInt(1, vehicleId);
            ps.setInt(2, (numWheelsStr == null || numWheelsStr.equals("")) ? 0 : Integer.parseInt(numWheelsStr));
            ps.setString(3, axleConfig);
            ps.executeUpdate();
            ps.close();
        }
        else if (type.equalsIgnoreCase("motorcycle")) {
            String sql = "INSERT INTO motorcycles (vehicle_id, has_sidecar, handlebar_style) VALUES (?, ?, ?)";
            ps = con.prepareStatement(sql);
            ps.setInt(1, vehicleId);
            ps.setInt(2, (hasSidecarStr == null || hasSidecarStr.equals("")) ? 0 : Integer.parseInt(hasSidecarStr));
            ps.setString(3, handlebarStyle);
            ps.executeUpdate();
            ps.close();
        }

        // 3. Insert into auctions
        String insertAuction =
            "INSERT INTO auctions (vehicle_id, seller_id, start_price, min_price, bid_increment, reserve_price, end_time) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?)";

        ps = con.prepareStatement(insertAuction);
        ps.setInt(1, vehicleId);
        ps.setInt(2, userId);
        ps.setDouble(3, Double.parseDouble(startPriceStr));
        ps.setDouble(4, Double.parseDouble(minPriceStr));
        ps.setDouble(5, Double.parseDouble(bidIncrementStr));

        if (reservePriceStr == null || reservePriceStr.trim().equals("")) {
            ps.setNull(6, java.sql.Types.DOUBLE);
        } else {
            ps.setDouble(6, Double.parseDouble(reservePriceStr));
        }

        // Convert datetime-local to SQL datetime
        ps.setTimestamp(7, Timestamp.valueOf(endTimeStr.replace("T", " ") + ":00"));

        ps.executeUpdate();
        ps.close();

        session.setAttribute("createOK", "Auction created successfully.");
        response.sendRedirect("auctions.jsp");
        return;

    } catch (Exception e) {
        session.setAttribute("createError", "Error creating auction: " + e.getMessage());
        response.sendRedirect("createListing.jsp");
        return;

    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>