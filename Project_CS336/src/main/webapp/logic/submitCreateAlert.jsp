<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>

<%
 
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");


    String category = request.getParameter("category_type");
    String make = request.getParameter("make");
    String model = request.getParameter("model");
    String yearMinStr = request.getParameter("year_min");
    String yearMaxStr = request.getParameter("year_max");
    String yearExactStr = request.getParameter("year_exact");
    String maxPriceStr = request.getParameter("max_price");
    String keyword = request.getParameter("keyword");

    String bodyStyle = request.getParameter("body_style");
    String numDoorsStr = request.getParameter("num_doors");

    String numWheelsStr = request.getParameter("num_wheels");
    String axleConfig = request.getParameter("axle_config");

    String hasSidecarStr = request.getParameter("has_sidecar");
    String handlebarStyle = request.getParameter("handlebar_style");

    String emailNotifyStr = request.getParameter("email_notify");


    if (category != null) category = category.trim();
    if (make != null) make = make.trim();
    if (model != null) model = model.trim();
    if (keyword != null) keyword = keyword.trim();

    if (bodyStyle != null) bodyStyle = bodyStyle.trim();
    if (axleConfig != null) axleConfig = axleConfig.trim();
    if (handlebarStyle != null) handlebarStyle = handlebarStyle.trim();


    String error = null;

    Integer yearMin = null;
    Integer yearMax = null;
    Integer yearExact = null;
    Double maxPrice = null;
    Integer numDoors = null;
    Integer numWheels = null;
    Integer hasSidecar = null;
    Integer emailNotify = (emailNotifyStr != null ? 1 : 0);

    try {
        if (yearMinStr != null && !yearMinStr.isEmpty())
            yearMin = Integer.parseInt(yearMinStr);
    } catch (Exception e) {
        error = "Year min must be a number.";
    }

    try {
        if (yearMaxStr != null && !yearMaxStr.isEmpty())
            yearMax = Integer.parseInt(yearMaxStr);
    } catch (Exception e) {
        error = "Year max must be a number.";
    }

    try {
        if (yearExactStr != null && !yearExactStr.isEmpty())
            yearExact = Integer.parseInt(yearExactStr);
    } catch (Exception e) {
        error = "Exact year must be a number.";
    }

    try {
        if (maxPriceStr != null && !maxPriceStr.isEmpty())
            maxPrice = Double.parseDouble(maxPriceStr);
    } catch (Exception e) {
        error = "Max price must be numeric.";
    }

    if ("car".equals(category)) {
        try {
            if (numDoorsStr != null && !numDoorsStr.isEmpty())
                numDoors = Integer.parseInt(numDoorsStr);
        } catch (Exception e) {
            error = "Number of doors must be a number.";
        }
    }

    if ("truck".equals(category)) {
        try {
            if (numWheelsStr != null && !numWheelsStr.isEmpty())
                numWheels = Integer.parseInt(numWheelsStr);
        } catch (Exception e) {
            error = "Number of wheels must be numeric.";
        }
    }

    if ("motorcycle".equals(category)) {
        try {
            if (hasSidecarStr != null && !hasSidecarStr.isEmpty())
                hasSidecar = Integer.parseInt(hasSidecarStr);
        } catch (Exception e) {
            error = "Sidecar must be 0 or 1.";
        }
    }

    if (error != null) {
        session.setAttribute("alertError", error);
        response.sendRedirect("../createAlert.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        String sql =
            "INSERT INTO alerts (" +
            "user_id, category_type, make, model, year_min, year_max, year_exact, " +
            "max_price, keyword, body_style, num_doors, num_wheels, axle_config, " +
            "has_sidecar, handlebar_style, email_notify" +
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        ps = con.prepareStatement(sql);

        ps.setInt(1, userId);

  
        ps.setString(2, empty(category));
        ps.setString(3, empty(make));
        ps.setString(4, empty(model));


        if (yearMin == null) ps.setNull(5, java.sql.Types.INTEGER); else ps.setInt(5, yearMin);
        if (yearMax == null) ps.setNull(6, java.sql.Types.INTEGER); else ps.setInt(6, yearMax);
        if (yearExact == null) ps.setNull(7, java.sql.Types.INTEGER); else ps.setInt(7, yearExact);

      
        if (maxPrice == null) ps.setNull(8, java.sql.Types.DOUBLE); else ps.setDouble(8, maxPrice);

      
        ps.setString(9, empty(keyword));

     
        ps.setString(10, empty(bodyStyle));
        setNullableInt(ps, 11, numDoors);

        setNullableInt(ps, 12, numWheels);
        ps.setString(13, empty(axleConfig));
        setNullableInt(ps, 14, hasSidecar);
        ps.setString(15, empty(handlebarStyle));

        ps.setInt(16, emailNotify);

        ps.executeUpdate();

        session.setAttribute("alertOK", "Alert created successfully.");
        response.sendRedirect("../createAlert.jsp");
        return;

    } catch (Exception ex) {
        session.setAttribute("alertError", "Database error: " + ex.getMessage());
        response.sendRedirect("../createAlert.jsp");
        return;

    } finally {
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }%>

<%! 

public String empty(String s) {
    return (s == null || s.trim().equals("")) ? null : s.trim();
}

public void setNullableInt(PreparedStatement ps, int idx, Integer val)
throws SQLException {
    if (val == null)
        ps.setNull(idx, java.sql.Types.INTEGER);
    else
        ps.setInt(idx, val);
}
%>