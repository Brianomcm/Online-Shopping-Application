package com.shopeasy;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class AppListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        OrderAutoCompleteScheduler.start();
        System.out.println("✅ Auto-complete scheduler started!");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        OrderAutoCompleteScheduler.stop();
        System.out.println("🛑 Auto-complete scheduler stopped.");
    }
}