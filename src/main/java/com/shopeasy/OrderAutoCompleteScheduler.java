package com.shopeasy;

import java.sql.*;
import java.util.concurrent.*;

public class OrderAutoCompleteScheduler {

    private static ScheduledExecutorService scheduler;

    public static void start() {
        scheduler = Executors.newSingleThreadScheduledExecutor();

        scheduler.scheduleAtFixedRate(() -> {
            try {
                Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE orders SET status='Completed', completed_at=NOW() " +
                    "WHERE status='Shipped' " +
                    "AND order_date <= NOW() - INTERVAL 7 DAY"
                );
                int updated = ps.executeUpdate();
                if (updated > 0) {
                    System.out.println("Auto-completed " + updated + " shipped order(s).");
                }
                ps.close();
                conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, 0, 24, TimeUnit.HOURS);
    }

    public static void stop() {
        if (scheduler != null) scheduler.shutdown();
    }
}